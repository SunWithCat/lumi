#pragma once

#include <jni.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <android/native_window.h>
#include <android/asset_manager.h>
#include <memory>
#include <atomic>
#include <thread>
#include <mutex>
#include <string>

class Live2DModel;

/**
 * Live2D 渲染器
 */
class Live2DRenderer {
public:
    Live2DRenderer();
    ~Live2DRenderer();

    bool Initialize(JNIEnv* env, jobject assetManager, jobject surfaceTexture, int width, int height);
    void Destroy();

    bool LoadModel(const std::string& modelPath);
    void UnloadModel();

    void PlayMotion(const std::string& group, int index, int priority);
    void SetExpression(const std::string& expressionId);
    std::string HitTest(float x, float y);
    void SetLookAt(float x, float y);

    void Pause();
    void Resume();

private:
    bool InitializeEGL(ANativeWindow* window);
    void DestroyEGL();
    void InitializeGL();
    
    void RenderLoop();
    void RenderFrame();

    // EGL
    EGLDisplay _eglDisplay;
    EGLContext _eglContext;
    EGLSurface _eglSurface;
    EGLConfig _eglConfig;

    // 渲染目标
    ANativeWindow* _nativeWindow;
    int _width;
    int _height;

    // Android
    AAssetManager* _assetManager;

    // 模型
    std::unique_ptr<Live2DModel> _model;
    std::mutex _modelMutex;
    
    // 模型加载请求（在渲染线程中处理）
    std::string _pendingModelPath;
    std::atomic<bool> _modelLoadRequested{false};

    // 渲染线程
    std::thread _renderThread;
    std::atomic<bool> _isRunning;
    std::atomic<bool> _shouldExit;

    // 帧率控制
    static constexpr float TARGET_FPS = 60.0f;
    static constexpr float FRAME_TIME = 1.0f / TARGET_FPS;
};
