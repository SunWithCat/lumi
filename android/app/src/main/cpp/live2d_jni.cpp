#include <jni.h>
#include "live2d_renderer.hpp"
#include "live2d_model.hpp"
#include <memory>
#include <android/log.h>

#define LOG_TAG "Live2DJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

static std::unique_ptr<Live2DRenderer> g_renderer;

// JNI_OnLoad - 保存 JavaVM
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("JNI_OnLoad");
    Live2DModel::SetJavaVM(vm);
    
    JNIEnv* env;
    if (vm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_OK) {
        Live2DModel::InitJNICallback(env);
    }
    
    return JNI_VERSION_1_6;
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeInit(
    JNIEnv* env,
    jobject thiz,
    jobject assetManager,
    jobject surfaceTexture,
    jint width,
    jint height
) {
    LOGI("nativeInit: %dx%d", width, height);
    
    if (g_renderer) {
        g_renderer->Destroy();
    }
    
    g_renderer = std::make_unique<Live2DRenderer>();
    return g_renderer->Initialize(env, assetManager, surfaceTexture, width, height);
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeDestroy(
    JNIEnv* env,
    jobject thiz
) {
    LOGI("nativeDestroy");
    
    if (g_renderer) {
        g_renderer->Destroy();
        g_renderer.reset();
    }
}

JNIEXPORT jboolean JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeLoadModel(
    JNIEnv* env,
    jobject thiz,
    jstring modelPath
) {
    if (!g_renderer) return JNI_FALSE;
    
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    bool result = g_renderer->LoadModel(path);
    env->ReleaseStringUTFChars(modelPath, path);
    
    return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativePlayMotion(
    JNIEnv* env,
    jobject thiz,
    jstring group,
    jint index,
    jint priority
) {
    if (!g_renderer) return;
    
    const char* groupStr = env->GetStringUTFChars(group, nullptr);
    g_renderer->PlayMotion(groupStr, index, priority);
    env->ReleaseStringUTFChars(group, groupStr);
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeSetExpression(
    JNIEnv* env,
    jobject thiz,
    jstring expressionId
) {
    if (!g_renderer) return;
    
    const char* id = env->GetStringUTFChars(expressionId, nullptr);
    g_renderer->SetExpression(id);
    env->ReleaseStringUTFChars(expressionId, id);
}

JNIEXPORT jstring JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeHitTest(
    JNIEnv* env,
    jobject thiz,
    jfloat x,
    jfloat y
) {
    if (!g_renderer) return env->NewStringUTF("");
    
    std::string result = g_renderer->HitTest(x, y);
    return env->NewStringUTF(result.c_str());
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeSetLookAt(
    JNIEnv* env,
    jobject thiz,
    jfloat x,
    jfloat y
) {
    if (!g_renderer) return;
    g_renderer->SetLookAt(x, y);
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativePause(
    JNIEnv* env,
    jobject thiz
) {
    if (g_renderer) {
        g_renderer->Pause();
    }
}

JNIEXPORT void JNICALL
Java_com_sunwithcat_lumi_live2d_Live2DNative_nativeResume(
    JNIEnv* env,
    jobject thiz
) {
    if (g_renderer) {
        g_renderer->Resume();
    }
}

} // extern "C"
