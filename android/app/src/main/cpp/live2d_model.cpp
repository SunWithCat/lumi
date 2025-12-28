#include "live2d_model.hpp"
#include <CubismModelSettingJson.hpp>
#include <Motion/CubismMotion.hpp>
#include <Physics/CubismPhysics.hpp>
#include <Rendering/OpenGL/CubismRenderer_OpenGLES2.hpp>
#include <Utils/CubismString.hpp>
#include <Id/CubismIdManager.hpp>
#include <CubismDefaultParameterId.hpp>
#include <Math/CubismModelMatrix.hpp>
#include <Effect/CubismEyeBlink.hpp>
#include <Effect/CubismBreath.hpp>
#include <GLES2/gl2.h>
#include <android/log.h>
#include <cstdlib>
#include <vector>
#include <jni.h>

#define LOG_TAG "Live2DModel"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

using namespace Csm;
using namespace DefaultParameterId;

// 全局 JNI 环境（由渲染线程设置）
static JavaVM* g_javaVM = nullptr;
static jclass g_live2dNativeClass = nullptr;
static jmethodID g_loadTextureMethod = nullptr;

void Live2DModel::SetJavaVM(JavaVM* vm) {
    g_javaVM = vm;
}

void Live2DModel::InitJNICallback(JNIEnv* env) {
    if (g_live2dNativeClass) return;
    
    jclass localClass = env->FindClass("com/sunwithcat/waifu/live2d/Live2DNative");
    if (localClass) {
        g_live2dNativeClass = (jclass)env->NewGlobalRef(localClass);
        g_loadTextureMethod = env->GetStaticMethodID(g_live2dNativeClass, "loadTexture", "(Ljava/lang/String;)[I");
        env->DeleteLocalRef(localClass);
        LOGI("JNI callback initialized");
    } else {
        LOGE("Failed to find Live2DNative class");
    }
}

Live2DModel::Live2DModel()
    : CubismUserModel()
    , _modelSetting(nullptr)
    , _motionManager(nullptr)
    , _expressionManager(nullptr)
    , _lookAtX(0.0f)
    , _lookAtY(0.0f) {
    
    _idParamAngleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
    _idParamAngleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
    _idParamAngleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
    _idParamBodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
    _idParamEyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
    _idParamEyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);
}

Live2DModel::~Live2DModel() {
    ReleaseMotions();
    ReleaseExpressions();
    
    for (csmUint32 i = 0; i < _textureIds.GetSize(); i++) {
        glDeleteTextures(1, &_textureIds[i]);
    }
    _textureIds.Clear();
    
    delete _modelSetting;
    delete _motionManager;
    delete _expressionManager;
}

bool Live2DModel::LoadAssets(AAssetManager* assetManager, const std::string& dir, const std::string& fileName) {
    _modelDir = dir;
    
    std::string path = dir + fileName;
    csmSizeInt size;
    csmByte* buffer = LoadFile(assetManager, path, &size);
    
    if (!buffer) {
        LOGE("Failed to load model setting: %s", path.c_str());
        return false;
    }
    
    _modelSetting = new CubismModelSettingJson(buffer, size);
    free(buffer);
    
    SetupModel(assetManager, dir);
    
    CreateRenderer();
    
    SetupTextures(assetManager, dir);
    
    LOGI("Model loaded successfully: %s", fileName.c_str());
    return true;
}

void Live2DModel::SetupModel(AAssetManager* assetManager, const std::string& dir) {
    // 加载 MOC3
    if (strcmp(_modelSetting->GetModelFileName(), "") != 0) {
        std::string path = dir + _modelSetting->GetModelFileName();
        csmSizeInt size;
        csmByte* buffer = LoadFile(assetManager, path, &size);
        
        if (buffer) {
            LoadModel(buffer, size);
            free(buffer);
        }
    }
    
    // 加载物理
    if (strcmp(_modelSetting->GetPhysicsFileName(), "") != 0) {
        std::string path = dir + _modelSetting->GetPhysicsFileName();
        csmSizeInt size;
        csmByte* buffer = LoadFile(assetManager, path, &size);
        
        if (buffer) {
            LoadPhysics(buffer, size);
            free(buffer);
            LOGI("Physics loaded");
        }
    }
    
    // 加载 Pose（手臂切换等）
    if (strcmp(_modelSetting->GetPoseFileName(), "") != 0) {
        std::string path = dir + _modelSetting->GetPoseFileName();
        csmSizeInt size;
        csmByte* buffer = LoadFile(assetManager, path, &size);
        
        if (buffer) {
            LoadPose(buffer, size);
            free(buffer);
            LOGI("Pose loaded");
        }
    }
    
    // 从 Layout 设置模型矩阵（关键！）
    csmMap<csmString, csmFloat32> layout;
    _modelSetting->GetLayoutMap(layout);
    _modelMatrix->SetupFromLayout(layout);
    LOGI("Model matrix setup from layout");
    
    // 保存参数
    _model->SaveParameters();
    
    // 眨眼参数
    csmInt32 eyeBlinkCount = _modelSetting->GetEyeBlinkParameterCount();
    for (csmInt32 i = 0; i < eyeBlinkCount; i++) {
        _eyeBlinkIds.PushBack(_modelSetting->GetEyeBlinkParameterId(i));
    }
    
    // 初始化眨眼
    if (_eyeBlinkIds.GetSize() > 0) {
        _eyeBlink = CubismEyeBlink::Create(_modelSetting);
        LOGI("EyeBlink initialized with %d parameters", _eyeBlinkIds.GetSize());
    }
    
    // 初始化呼吸
    _breath = CubismBreath::Create();
    csmVector<CubismBreath::BreathParameterData> breathParameters;
    breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleX, 0.0f, 15.0f, 6.5345f, 0.5f));
    breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleY, 0.0f, 8.0f, 3.5345f, 0.5f));
    breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleZ, 0.0f, 10.0f, 5.5345f, 0.5f));
    breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamBodyAngleX, 0.0f, 4.0f, 15.5345f, 0.5f));
    breathParameters.PushBack(CubismBreath::BreathParameterData(
        CubismFramework::GetIdManager()->GetId(DefaultParameterId::ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));
    _breath->SetParameters(breathParameters);
    LOGI("Breath initialized");
    
    // 口型参数
    csmInt32 lipSyncCount = _modelSetting->GetLipSyncParameterCount();
    for (csmInt32 i = 0; i < lipSyncCount; i++) {
        _lipSyncIds.PushBack(_modelSetting->GetLipSyncParameterId(i));
    }
    
    // 动作管理器
    _motionManager = new CubismMotionManager();
    _motionManager->SetEventCallback(nullptr, nullptr);
    
    _expressionManager = new CubismMotionManager();
    
    // 预加载动作
    PreloadMotions(assetManager, dir);
    
    // 初始化 Pose 状态（重要：解决多余手臂问题）
    if (_pose) {
        _pose->Reset(_model);
        LOGI("Pose reset");
    }
}

void Live2DModel::SetupTextures(AAssetManager* assetManager, const std::string& dir) {
    csmInt32 textureCount = _modelSetting->GetTextureCount();
    
    LOGI("SetupTextures: Loading %d textures", textureCount);
    
    // 获取 JNI 环境
    JNIEnv* env = nullptr;
    bool needDetach = false;
    
    if (g_javaVM) {
        jint result = g_javaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
        if (result == JNI_EDETACHED) {
            g_javaVM->AttachCurrentThread(&env, nullptr);
            needDetach = true;
            LOGI("Attached to JNI thread");
        }
    }
    
    for (csmInt32 i = 0; i < textureCount; i++) {
        std::string texturePath = dir + _modelSetting->GetTextureFileName(i);
        
        GLuint textureId = 0;
        bool textureLoaded = false;
        
        // 尝试通过 JNI 回调加载纹理
        if (env && g_live2dNativeClass && g_loadTextureMethod) {
            jstring jPath = env->NewStringUTF(texturePath.c_str());
            jintArray jResult = (jintArray)env->CallStaticObjectMethod(g_live2dNativeClass, g_loadTextureMethod, jPath);
            env->DeleteLocalRef(jPath);
            
            if (jResult) {
                jint* data = env->GetIntArrayElements(jResult, nullptr);
                jsize len = env->GetArrayLength(jResult);
                
                if (len >= 2) {
                    int width = data[0];
                    int height = data[1];
                    
                    LOGI("Creating GL texture: %s (%dx%d)", texturePath.c_str(), width, height);
                    
                    // 创建 OpenGL 纹理
                    glGenTextures(1, &textureId);
                    glBindTexture(GL_TEXTURE_2D, textureId);
                    
                    // 检查纹理创建是否成功
                    GLenum err = glGetError();
                    if (err != GL_NO_ERROR) {
                        LOGE("glGenTextures error: 0x%x", err);
                    }
                    
                    // Android Bitmap 是 ARGB_8888，需要转换为 RGBA
                    // 同时需要预乘 alpha
                    std::vector<unsigned char> rgba(width * height * 4);
                    for (int j = 0; j < width * height; j++) {
                        int argb = data[2 + j];
                        unsigned char a = (argb >> 24) & 0xFF;
                        unsigned char r = (argb >> 16) & 0xFF;
                        unsigned char g = (argb >> 8) & 0xFF;
                        unsigned char b = argb & 0xFF;
                        
                        // 预乘 alpha
                        rgba[j * 4 + 0] = (r * a) / 255;
                        rgba[j * 4 + 1] = (g * a) / 255;
                        rgba[j * 4 + 2] = (b * a) / 255;
                        rgba[j * 4 + 3] = a;
                    }
                    
                    // 上传纹理数据
                    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba.data());
                    
                    // 生成 mipmap
                    glGenerateMipmap(GL_TEXTURE_2D);
                    
                    // 设置纹理参数
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    
                    // 解绑纹理
                    glBindTexture(GL_TEXTURE_2D, 0);
                    
                    err = glGetError();
                    if (err != GL_NO_ERROR) {
                        LOGE("glTexImage2D error: 0x%x", err);
                    } else {
                        textureLoaded = true;
                        LOGI("Texture %d created with GL id %u", i, textureId);
                    }
                }
                
                env->ReleaseIntArrayElements(jResult, data, 0);
                env->DeleteLocalRef(jResult);
            } else {
                LOGE("JNI loadTexture returned null for: %s", texturePath.c_str());
            }
        } else {
            LOGE("JNI not available for texture loading");
        }
        
        // 如果加载失败，创建占位纹理
        if (!textureLoaded) {
            LOGE("Failed to load texture, using placeholder: %s", texturePath.c_str());
            glGenTextures(1, &textureId);
            glBindTexture(GL_TEXTURE_2D, textureId);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            unsigned char white[] = {255, 255, 255, 255};
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, white);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        _textureIds.PushBack(textureId);
        GetRenderer<Rendering::CubismRenderer_OpenGLES2>()->BindTexture(i, textureId);
        LOGI("Bound texture %d to renderer slot %d", textureId, i);
    }
    
    if (needDetach && g_javaVM) {
        g_javaVM->DetachCurrentThread();
    }
    
    // 设置预乘 alpha（我们在上面已经预乘了）
    GetRenderer<Rendering::CubismRenderer_OpenGLES2>()->IsPremultipliedAlpha(true);
    LOGI("SetupTextures complete");
}

void Live2DModel::PreloadMotions(AAssetManager* assetManager, const std::string& dir) {
    csmInt32 groupCount = _modelSetting->GetMotionGroupCount();
    
    for (csmInt32 g = 0; g < groupCount; g++) {
        const csmChar* group = _modelSetting->GetMotionGroupName(g);
        csmInt32 count = _modelSetting->GetMotionCount(group);
        
        for (csmInt32 i = 0; i < count; i++) {
            std::string name = std::string(group) + "_" + std::to_string(i);
            std::string path = dir + _modelSetting->GetMotionFileName(group, i);
            
            csmSizeInt size;
            csmByte* buffer = LoadFile(assetManager, path, &size);
            
            if (buffer) {
                CubismMotion* motion = CubismMotion::Create(buffer, size);
                
                if (motion) {
                    float fadeIn = _modelSetting->GetMotionFadeInTimeValue(group, i);
                    float fadeOut = _modelSetting->GetMotionFadeOutTimeValue(group, i);
                    
                    if (fadeIn >= 0.0f) motion->SetFadeInTime(fadeIn);
                    if (fadeOut >= 0.0f) motion->SetFadeOutTime(fadeOut);
                    
                    _motions[name.c_str()] = motion;
                    LOGI("Motion loaded: %s", name.c_str());
                }
                
                free(buffer);
            }
        }
    }
}

void Live2DModel::Update(float deltaTime) {
    _model->LoadParameters();
    
    bool motionUpdated = _motionManager->UpdateMotion(_model, deltaTime);
    
    // 如果没有动作在播放，自动播放 idle 动作
    if (!motionUpdated && _motionManager->IsFinished()) {
        // 尝试播放 Idle 动作
        StartMotion("Idle", 0, 1);
    }
    
    if (!motionUpdated) {
        if (_eyeBlink) {
            _eyeBlink->UpdateParameters(_model, deltaTime);
        }
    }
    
    _expressionManager->UpdateMotion(_model, deltaTime);
    
    _model->SaveParameters();
    
    // 视线跟随
    _model->AddParameterValue(_idParamAngleX, _lookAtX * 30.0f);
    _model->AddParameterValue(_idParamAngleY, _lookAtY * 30.0f);
    _model->AddParameterValue(_idParamEyeBallX, _lookAtX);
    _model->AddParameterValue(_idParamEyeBallY, _lookAtY);
    
    // 呼吸效果
    if (_breath) {
        _breath->UpdateParameters(_model, deltaTime);
    }
    
    if (_physics) {
        _physics->Evaluate(_model, deltaTime);
    }
    
    if (_pose) {
        _pose->UpdateParameters(_model, deltaTime);
    }
    
    _model->Update();
}

void Live2DModel::Draw(CubismMatrix44& matrix) {
    if (!_model) {
        return;
    }
    
    // 清除之前的 OpenGL 错误
    while (glGetError() != GL_NO_ERROR) {}
    
    // 确保正确的 OpenGL 状态
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);  // 预乘 alpha 的混合模式
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    // 重新绑定纹理
    for (csmUint32 i = 0; i < _textureIds.GetSize(); i++) {
        GetRenderer<Rendering::CubismRenderer_OpenGLES2>()->BindTexture(i, _textureIds[i]);
    }
    
    // 按照官方示例的方式：将模型矩阵乘到投影矩阵上
    matrix.MultiplyByMatrix(_modelMatrix);
    
    Rendering::CubismRenderer_OpenGLES2* renderer = GetRenderer<Rendering::CubismRenderer_OpenGLES2>();
    renderer->SetMvpMatrix(&matrix);
    renderer->DrawModel();
}

void Live2DModel::StartMotion(const std::string& group, int index, int priority) {
    std::string name = group + "_" + std::to_string(index);
    
    CubismMotion* motion = static_cast<CubismMotion*>(_motions[name.c_str()]);
    
    if (motion) {
        _motionManager->StartMotionPriority(motion, false, priority);
        LOGI("Start motion: %s", name.c_str());
    } else {
        LOGE("Motion not found: %s", name.c_str());
    }
}

void Live2DModel::SetExpression(const std::string& expressionId) {
    ACubismMotion* motion = _expressions[expressionId.c_str()];
    
    if (motion) {
        _expressionManager->StartMotionPriority(motion, false, 3);
        LOGI("Set expression: %s", expressionId.c_str());
    }
}

std::string Live2DModel::HitTest(float x, float y) {
    if (!_modelSetting) return "";
    
    csmInt32 count = _modelSetting->GetHitAreasCount();
    
    for (csmInt32 i = 0; i < count; i++) {
        const csmChar* area = _modelSetting->GetHitAreaName(i);
        const CubismIdHandle drawId = _modelSetting->GetHitAreaId(i);
        
        if (IsHit(drawId, x, y)) {
            return area;
        }
    }
    
    return "";
}

void Live2DModel::SetLookAt(float x, float y) {
    _lookAtX = x;
    _lookAtY = y;
}

csmByte* Live2DModel::LoadFile(AAssetManager* assetManager, const std::string& path, csmSizeInt* outSize) {
    AAsset* asset = AAssetManager_open(assetManager, path.c_str(), AASSET_MODE_BUFFER);
    
    if (!asset) {
        LOGE("Failed to open asset: %s", path.c_str());
        return nullptr;
    }
    
    csmSizeInt size = AAsset_getLength(asset);
    csmByte* buffer = static_cast<csmByte*>(malloc(size));
    
    AAsset_read(asset, buffer, size);
    AAsset_close(asset);
    
    *outSize = size;
    return buffer;
}

void Live2DModel::ReleaseMotions() {
    for (auto iter = _motions.Begin(); iter != _motions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _motions.Clear();
}

void Live2DModel::ReleaseExpressions() {
    for (auto iter = _expressions.Begin(); iter != _expressions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _expressions.Clear();
}
