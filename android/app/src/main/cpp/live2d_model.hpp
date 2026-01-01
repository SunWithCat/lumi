#pragma once

#include <CubismFramework.hpp>
#include <Model/CubismUserModel.hpp>
#include <ICubismModelSetting.hpp>
#include <Motion/CubismMotionManager.hpp>
#include <Type/csmVector.hpp>
#include <string>
#include <android/asset_manager.h>
#include <jni.h>

/**
 * Live2D 模型封装类
 */
class Live2DModel : public Csm::CubismUserModel {
public:
    Live2DModel();
    ~Live2DModel();

    /**
     * 设置 JavaVM（用于 JNI 回调）
     */
    static void SetJavaVM(JavaVM* vm);
    
    /**
     * 初始化 JNI 回调
     */
    static void InitJNICallback(JNIEnv* env);

    /**
     * 从 Assets 加载模型
     */
    bool LoadAssets(AAssetManager* assetManager, const std::string& dir, const std::string& fileName);

    /**
     * 更新模型
     */
    void Update(float deltaTime);

    /**
     * 绘制模型
     */
    void Draw(Csm::CubismMatrix44& matrix);

    /**
     * 播放动作
     */
    void StartMotion(const std::string& group, int index, int priority);
    
    /**
     * 播放随机待机动作
     */
    void StartRandomIdleMotion();

    /**
     * 设置表情
     */
    void SetExpression(const std::string& expressionId);

    /**
     * 触摸测试
     */
    std::string HitTest(float x, float y);

    /**
     * 设置视线目标
     */
    void SetLookAt(float x, float y);
    
    /**
     * 获取全局实例（用于回调）
     */
    static Live2DModel* GetInstance() { return s_instance; }

private:
    void SetupModel(AAssetManager* assetManager, const std::string& dir);
    void SetupTextures(AAssetManager* assetManager, const std::string& dir);
    void PreloadMotions(AAssetManager* assetManager, const std::string& dir);
    
    /**
     * 动作结束回调（静态函数）
     */
    static void OnMotionFinished(Csm::ACubismMotion* motion);
    
    /**
     * 清除所有动作的回调（防止残留回调干扰）
     */
    void ClearAllMotionCallbacks();
    
    // 全局实例指针（用于回调访问）
    static Live2DModel* s_instance;
    
    Csm::csmByte* LoadFile(AAssetManager* assetManager, const std::string& path, Csm::csmSizeInt* outSize);
    void ReleaseMotions();
    void ReleaseExpressions();

    Csm::ICubismModelSetting* _modelSetting;
    std::string _modelDir;
    
    Csm::CubismMotionManager* _motionManager;
    Csm::CubismMotionManager* _expressionManager;
    
    Csm::csmVector<Csm::CubismIdHandle> _eyeBlinkIds;
    Csm::csmVector<Csm::CubismIdHandle> _lipSyncIds;
    
    Csm::csmMap<std::string, Csm::ACubismMotion*> _motions;
    Csm::csmMap<std::string, Csm::ACubismMotion*> _expressions;
    
    Csm::csmVector<Csm::csmUint32> _textureIds;
    
    float _lookAtX;
    float _lookAtY;
    
    // Idle 动作相关
    Csm::csmInt32 _idleMotionCount;  // Idle 动作数量
    
    const Csm::CubismId* _idParamAngleX;
    const Csm::CubismId* _idParamAngleY;
    const Csm::CubismId* _idParamAngleZ;
    const Csm::CubismId* _idParamBodyAngleX;
    const Csm::CubismId* _idParamEyeBallX;
    const Csm::CubismId* _idParamEyeBallY;
};
