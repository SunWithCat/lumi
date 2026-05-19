#include "live2d_renderer.hpp"
#include "live2d_model.hpp"
#include "live2d_allocator.hpp"
#include <CubismFramework.hpp>
#include <Math/CubismMatrix44.hpp>
#include <android/native_window_jni.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <chrono>
#include <cstdlib>
#include <string>

#define LOG_TAG "Live2DRenderer"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

using namespace Csm;

static Live2DAllocator s_allocator;
static CubismFramework::Option s_option;

// 全局 AssetManager 用于 shader 加载
static AAssetManager* g_assetManager = nullptr;

// Cubism Framework 文件加载回调
static csmByte* LoadFileAsBytes(const std::string filePath, csmSizeInt* outSize) {
    if (!g_assetManager) {
        LOGE("LoadFileAsBytes: AssetManager is null");
        return nullptr;
    }
    
    AAsset* asset = AAssetManager_open(g_assetManager, filePath.c_str(), AASSET_MODE_BUFFER);
    if (!asset) {
        LOGE("LoadFileAsBytes: Failed to open asset: %s", filePath.c_str());
        return nullptr;
    }
    
    csmSizeInt size = AAsset_getLength(asset);
    csmByte* buffer = static_cast<csmByte*>(malloc(size));
    
    AAsset_read(asset, buffer, size);
    AAsset_close(asset);
    
    *outSize = size;
    LOGI("LoadFileAsBytes: Loaded %s (%d bytes)", filePath.c_str(), size);
    return buffer;
}

// Cubism Framework 内存释放回调
static void ReleaseBytes(csmByte* bytes) {
    free(bytes);
}

Live2DRenderer::Live2DRenderer()
    : _eglDisplay(EGL_NO_DISPLAY)
    , _eglContext(EGL_NO_CONTEXT)
    , _eglSurface(EGL_NO_SURFACE)
    , _eglConfig(nullptr)
    , _nativeWindow(nullptr)
    , _width(0)
    , _height(0)
    , _assetManager(nullptr)
    , _isRunning(false)
    , _shouldExit(false) {
}

Live2DRenderer::~Live2DRenderer() {
    Destroy();
}

bool Live2DRenderer::Initialize(JNIEnv* env, jobject assetManager, jobject surface, int width, int height) {
    LOGI("Initializing renderer: %dx%d", width, height);
    
    _width = width;
    _height = height;
    
    // 获取 AssetManager
    _assetManager = AAssetManager_fromJava(env, assetManager);
    if (!_assetManager) {
        LOGE("Failed to get AssetManager");
        return false;
    }
    
    // 从 SurfaceTexture 获取 ANativeWindow
    // jclass surfaceTextureClass = env->GetObjectClass(surfaceTexture);
    // jclass surfaceClass = env->FindClass("android/view/Surface");
    // jmethodID surfaceConstructor = env->GetMethodID(surfaceClass, "<init>", "(Landroid/graphics/SurfaceTexture;)V");
    // jobject surface = env->NewObject(surfaceClass, surfaceConstructor, surfaceTexture);
    
    _nativeWindow = ANativeWindow_fromSurface(env, surface);
    if (!_nativeWindow) {
        LOGE("Failed to get ANativeWindow");
        return false;
    }
    
    ANativeWindow_setBuffersGeometry(_nativeWindow, width, height, AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM);
    
    // env->DeleteLocalRef(surface);
    // env->DeleteLocalRef(surfaceClass);
    // env->DeleteLocalRef(surfaceTextureClass);
    
    // 启动渲染线程（Cubism Framework 将在渲染线程中初始化）
    _shouldExit.store(false);
    _isRunning.store(true);
    
    _renderThread = std::thread([this]() {
        if (!InitializeEGL(_nativeWindow)) {
            LOGE("Failed to initialize EGL");
            _isRunning.store(false);
            return;
        }
        
        // 设置全局 AssetManager
        g_assetManager = _assetManager;
        
        // 在渲染线程中初始化 Cubism Framework（需要 OpenGL 上下文）
        s_option.LogFunction = [](const csmChar* message) {
            LOGI("Cubism: %s", message);
        };
        s_option.LoggingLevel = CubismFramework::Option::LogLevel_Verbose;
        s_option.LoadFileFunction = LoadFileAsBytes;
        s_option.ReleaseBytesFunction = ReleaseBytes;
        
        CubismFramework::StartUp(&s_allocator, &s_option);
        CubismFramework::Initialize();
        
        InitializeGL();
        RenderLoop();
        
        // 清理 Cubism Framework
        CubismFramework::Dispose();
        
        DestroyEGL();
    });
    
    LOGI("Renderer initialized");
    return true;
}

void Live2DRenderer::Destroy() {
    LOGI("Destroying renderer");
    
    _shouldExit.store(true);
    _isRunning.store(false);
    
    if (_renderThread.joinable()) {
        _renderThread.join();
    }
    
    {
        std::lock_guard<std::mutex> lock(_modelMutex);
        _model.reset();
    }
    
    // CubismFramework::Dispose() 已在渲染线程中调用
    
    if (_nativeWindow) {
        ANativeWindow_release(_nativeWindow);
        _nativeWindow = nullptr;
    }
    
    LOGI("Renderer destroyed");
}

bool Live2DRenderer::InitializeEGL(ANativeWindow* window) {
    _eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (_eglDisplay == EGL_NO_DISPLAY) {
        LOGE("eglGetDisplay failed");
        return false;
    }
    
    EGLint majorVersion, minorVersion;
    if (!eglInitialize(_eglDisplay, &majorVersion, &minorVersion)) {
        LOGE("eglInitialize failed");
        return false;
    }
    
    const EGLint configAttribs[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 0,
        EGL_NONE
    };
    
    EGLint numConfigs;
    if (!eglChooseConfig(_eglDisplay, configAttribs, &_eglConfig, 1, &numConfigs) || numConfigs == 0) {
        LOGE("eglChooseConfig failed");
        return false;
    }
    
    _eglSurface = eglCreateWindowSurface(_eglDisplay, _eglConfig, window, nullptr);
    if (_eglSurface == EGL_NO_SURFACE) {
        LOGE("eglCreateWindowSurface failed");
        return false;
    }
    
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    };
    
    _eglContext = eglCreateContext(_eglDisplay, _eglConfig, EGL_NO_CONTEXT, contextAttribs);
    if (_eglContext == EGL_NO_CONTEXT) {
        LOGE("eglCreateContext failed");
        return false;
    }
    
    if (!eglMakeCurrent(_eglDisplay, _eglSurface, _eglSurface, _eglContext)) {
        LOGE("eglMakeCurrent failed");
        return false;
    }
    
    eglSwapInterval(_eglDisplay, 1);
    
    LOGI("EGL initialized");
    return true;
}

void Live2DRenderer::DestroyEGL() {
    if (_eglDisplay != EGL_NO_DISPLAY) {
        eglMakeCurrent(_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        
        if (_eglContext != EGL_NO_CONTEXT) {
            eglDestroyContext(_eglDisplay, _eglContext);
        }
        
        if (_eglSurface != EGL_NO_SURFACE) {
            eglDestroySurface(_eglDisplay, _eglSurface);
        }
        
        eglTerminate(_eglDisplay);
    }
    
    _eglDisplay = EGL_NO_DISPLAY;
    _eglContext = EGL_NO_CONTEXT;
    _eglSurface = EGL_NO_SURFACE;
}

void Live2DRenderer::InitializeGL() {
    glViewport(0, 0, _width, _height);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}

void Live2DRenderer::RenderLoop() {
    LOGI("Render loop started");
    
    auto lastTime = std::chrono::steady_clock::now();
    
    while (!_shouldExit.load()) {
        // 暂停时只睡眠，不渲染（节省 CPU/GPU 资源）
        if (!_isRunning.load()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            lastTime = std::chrono::steady_clock::now();  // 重置时间，避免恢复时 deltaTime 过大
            continue;
        }
        
        auto currentTime = std::chrono::steady_clock::now();
        float deltaTime = std::chrono::duration<float>(currentTime - lastTime).count();
        
        if (deltaTime < FRAME_TIME) {
            std::this_thread::sleep_for(std::chrono::duration<float>(FRAME_TIME - deltaTime));
            currentTime = std::chrono::steady_clock::now();
            deltaTime = std::chrono::duration<float>(currentTime - lastTime).count();
        }
        
        lastTime = currentTime;
        
        {
            std::lock_guard<std::mutex> lock(_modelMutex);
            
            // 在渲染线程中加载模型（确保 OpenGL 上下文有效）
            if (_modelLoadRequested) {
                LOGI("Loading model in render thread: %s", _pendingModelPath.c_str());
                
                _model.reset();
                _model = std::make_unique<Live2DModel>();
                
                size_t lastSlash = _pendingModelPath.find_last_of('/');
                std::string dir = _pendingModelPath.substr(0, lastSlash + 1);
                std::string fileName = _pendingModelPath.substr(lastSlash + 1);
                
                bool success = _model->LoadAssets(_assetManager, dir, fileName);
                
                if (!success) {
                    _model.reset();
                    LOGE("Failed to load model");
                } else {
                    LOGI("Model loaded successfully in render thread");
                }
                
                _modelLoadRequested = false;
            }
            
            // 只有在运行状态才更新模型（暂停时保持静止）
            if (_model && _isRunning.load()) {
                _model->Update(deltaTime);
            }
            
            RenderFrame();
        }
        
        eglSwapBuffers(_eglDisplay, _eglSurface);
    }
    
    LOGI("Render loop ended");
}

void Live2DRenderer::RenderFrame() {
    // 透明背景
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!_model) {
        return;
    }
    
    // 重新设置 OpenGL 状态
    glViewport(0, 0, _width, _height);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);  // 预乘 alpha 的混合模式
    
    // 创建投影矩阵
    CubismMatrix44 projection;
    projection.LoadIdentity();
    
    // 保持模型比例，不拉伸
    // 纹理是正方形 (512x512)，所以不需要额外缩放
    // 模型坐标系是 -1 到 1
    
    // 绘制模型（Draw 内部会乘以模型矩阵）
    _model->Draw(projection);
}

bool Live2DRenderer::LoadModel(const std::string& modelPath) {
    LOGI("LoadModel request: %s", modelPath.c_str());
    
    // 保存模型路径，在渲染线程中加载
    {
        std::lock_guard<std::mutex> lock(_modelMutex);
        _pendingModelPath = modelPath;
        _modelLoadRequested = true;
    }
    
    // 等待加载完成（最多等待 5 秒）- 不持有锁
    for (int i = 0; i < 50; i++) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> lock(_modelMutex);
        if (!_modelLoadRequested) {
            break;
        }
    }
    
    std::lock_guard<std::mutex> lock(_modelMutex);
    bool result = _model != nullptr;
    LOGI("LoadModel result: %s (model=%p)", result ? "true" : "false", _model.get());
    return result;
}

void Live2DRenderer::UnloadModel() {
    std::lock_guard<std::mutex> lock(_modelMutex);
    _model.reset();
}

void Live2DRenderer::PlayMotion(const std::string& group, int index, int priority) {
    LOGI("PlayMotion: %s[%d] priority=%d", group.c_str(), index, priority);
    std::lock_guard<std::mutex> lock(_modelMutex);
    if (_model) {
        _model->StartMotion(group, index, priority);
    } else {
        LOGI("PlayMotion: model is null");
    }
}

void Live2DRenderer::SetExpression(const std::string& expressionId) {
    std::lock_guard<std::mutex> lock(_modelMutex);
    if (_model) {
        _model->SetExpression(expressionId);
    }
}

std::string Live2DRenderer::HitTest(float x, float y) {
    std::lock_guard<std::mutex> lock(_modelMutex);
    if (_model) {
        return _model->HitTest(x, y);
    }
    return "";
}

void Live2DRenderer::SetLookAt(float x, float y) {
    std::lock_guard<std::mutex> lock(_modelMutex);
    if (_model) {
        _model->SetLookAt(x, y);
    }
}

void Live2DRenderer::Pause() {
    _isRunning.store(false);
}

void Live2DRenderer::Resume() {
    _isRunning.store(true);
}
