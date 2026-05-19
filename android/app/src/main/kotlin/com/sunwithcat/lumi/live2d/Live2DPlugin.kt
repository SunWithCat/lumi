package com.sunwithcat.lumi.live2d

import android.content.Context
import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * Live2D Flutter 插件
 */
class Live2DPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "Live2DPlugin"
        private const val CHANNEL = "com.sunwithcat.lumi/live2d"
        private const val EVENT_CHANNEL = "com.sunwithcat.lumi/live2d/events"
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var textureRegistry: TextureRegistry

//    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Native 渲染器是否可用
    private var isNativeAvailable = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textureRegistry = binding.textureRegistry

        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        // 检查 native 库是否可用
        isNativeAvailable = checkNativeLibrary()
        Log.d(TAG, "Native library available: $isNativeAvailable")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "destroy" -> handleDestroy(result)
            "loadModel" -> handleLoadModel(call, result)
            "playMotion" -> handlePlayMotion(call, result)
            "setExpression" -> handleSetExpression(call, result)
            "hitTest" -> handleHitTest(call, result)
            "setLookAt" -> handleSetLookAt(call, result)
            "pause" -> handlePause(result)
            "resume" -> handleResume(result)
            else -> result.notImplemented()
        }
    }

    private fun checkNativeLibrary(): Boolean {
        return try {
            System.loadLibrary("live2d_native")
            true
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "Native library not found, using mock mode")
            false
        }
    }

    private var surfaceProducer: TextureRegistry.SurfaceProducer? = null

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        val width = call.argument<Int>("width") ?: 512
        val height = call.argument<Int>("height") ?: 512

        try {
            surfaceProducer = textureRegistry.createSurfaceProducer()
            surfaceProducer!!.setSize(width, height)
            val surface = surfaceProducer!!.surface
//            textureEntry = textureRegistry.createSurfaceTexture()
//            val surfaceTexture = textureEntry!!.surfaceTexture()
//            surfaceTexture.setDefaultBufferSize(width, height)

            if (isNativeAvailable) {
                // 设置 AssetManager 供纹理加载回调使用
                Live2DNative.setAssetManager(context.assets)
                
                val success = Live2DNative.nativeInit(
                    context.assets,
                    surface,
                    width,
                    height
                )
                if (!success) {
                    surfaceProducer?.release()
                    result.error("INIT_FAILED", "Native init failed", null)
                    return
                }
            }

            Log.d(TAG, "Initialized, textureId=${surfaceProducer!!.id()}")
            result.success(mapOf("textureId" to surfaceProducer!!.id()))

        } catch (e: Exception) {
            Log.e(TAG, "Initialize error", e)
            surfaceProducer?.release()
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun handleDestroy(result: MethodChannel.Result) {
        destroy()
        result.success(null)
    }

    private fun destroy() {
        if (isNativeAvailable) {
            try {
                Live2DNative.nativeDestroy()
            } catch (e: Exception) {
                Log.e(TAG, "Native destroy error", e)
            }
        }
        surfaceProducer?.release()
        surfaceProducer = null
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("INVALID_ARGS", "path required", null)
            return
        }

        if (!isNativeAvailable) {
            // Mock 模式：假装加载成功
            Log.d(TAG, "Mock: loadModel $path")
            result.success(true)
            return
        }

        Thread {
            try {
                val success = Live2DNative.nativeLoadModel(path)
                mainHandler.post { result.success(success) }
            } catch (e: Exception) {
                mainHandler.post { result.error("LOAD_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun handlePlayMotion(call: MethodCall, result: MethodChannel.Result) {
        val group = call.argument<String>("group") ?: return
        val index = call.argument<Int>("index") ?: 0
        val priority = call.argument<Int>("priority") ?: 2

        if (!isNativeAvailable) {
            Log.d(TAG, "Mock: playMotion $group[$index]")
            // 模拟动作完成回调
            mainHandler.postDelayed({
                sendMotionFinished(group, index)
            }, 1000)
            result.success(null)
            return
        }

        try {
            Live2DNative.nativePlayMotion(group, index, priority)
            result.success(null)
        } catch (e: Exception) {
            result.error("MOTION_ERROR", e.message, null)
        }
    }

    // 模型的动作已经自带表情，这个方法暂时没用
    private fun handleSetExpression(call: MethodCall, result: MethodChannel.Result) {
        val expressionId = call.argument<String>("expressionId") ?: return

        if (!isNativeAvailable) {
            Log.d(TAG, "Mock: setExpression $expressionId")
            result.success(null)
            return
        }

        try {
            Live2DNative.nativeSetExpression(expressionId)
            result.success(null)
        } catch (e: Exception) {
            result.error("EXPRESSION_ERROR", e.message, null)
        }
    }

    private fun handleHitTest(call: MethodCall, result: MethodChannel.Result) {
        val x = call.argument<Double>("x")?.toFloat() ?: return
        val y = call.argument<Double>("y")?.toFloat() ?: return

        if (!isNativeAvailable) {
            // Mock: 简单区域判断
            val hitArea = when {
                y < 0.3 -> "head"
                y < 0.7 -> "body"
                else -> ""
            }
            Log.d(TAG, "Mock: hitTest ($x, $y) -> $hitArea")
            result.success(hitArea)
            return
        }

        try {
            val hitArea = Live2DNative.nativeHitTest(x, y)
            result.success(hitArea)
        } catch (e: Exception) {
            result.error("HIT_TEST_ERROR", e.message, null)
        }
    }

    private fun handleSetLookAt(call: MethodCall, result: MethodChannel.Result) {
        val x = call.argument<Double>("x")?.toFloat() ?: 0f
        val y = call.argument<Double>("y")?.toFloat() ?: 0f

        if (!isNativeAvailable) {
            result.success(null)
            return
        }

        try {
            Live2DNative.nativeSetLookAt(x, y)
            result.success(null)
        } catch (e: Exception) {
            result.error("LOOK_AT_ERROR", e.message, null)
        }
    }

    private fun handlePause(result: MethodChannel.Result) {
        if (!isNativeAvailable) {
            result.success(null)
            return
        }

        try {
            Live2DNative.nativePause()
            Log.d(TAG, "Renderer paused")
            result.success(null)
        } catch (e: Exception) {
            result.error("PAUSE_ERROR", e.message, null)
        }
    }

    private fun handleResume(result: MethodChannel.Result) {
        if (!isNativeAvailable) {
            result.success(null)
            return
        }

        try {
            Live2DNative.nativeResume()
            Log.d(TAG, "Renderer resumed")
            result.success(null)
        } catch (e: Exception) {
            result.error("RESUME_ERROR", e.message, null)
        }
    }

    // EventChannel
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendMotionFinished(group: String, index: Int) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "motionFinished",
                "group" to group,
                "index" to index
            ))
        }
    }
}
