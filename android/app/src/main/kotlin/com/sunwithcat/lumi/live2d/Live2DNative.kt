package com.sunwithcat.lumi.live2d

import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.SurfaceTexture
import android.util.Log
import java.nio.ByteBuffer

/**
 * Live2D Native JNI 接口
 */
object Live2DNative {
    private const val TAG = "Live2DNative"
    private var assetManager: AssetManager? = null

    fun setAssetManager(am: AssetManager) {
        assetManager = am
    }

    external fun nativeInit(
        assetManager: AssetManager,
        surfaceTexture: SurfaceTexture,
        width: Int,
        height: Int
    ): Boolean

    external fun nativeDestroy()

    external fun nativeLoadModel(modelPath: String): Boolean

    external fun nativePlayMotion(group: String, index: Int, priority: Int)

    external fun nativeSetExpression(expressionId: String)

    external fun nativeHitTest(x: Float, y: Float): String

    external fun nativeSetLookAt(x: Float, y: Float)

    external fun nativePause()

    external fun nativeResume()

    /**
     * 从 C++ 回调，加载纹理图片
     * @return IntArray: [width, height, ...pixel_data_as_RGBA]
     */
    @JvmStatic
    fun loadTexture(path: String): IntArray? {
        Log.i(TAG, "loadTexture: $path")
        val am = assetManager ?: return null
        
        return try {
            am.open(path).use { inputStream ->
                val bitmap = BitmapFactory.decodeStream(inputStream)
                if (bitmap == null) {
                    Log.e(TAG, "Failed to decode bitmap: $path")
                    return null
                }
                
                val width = bitmap.width
                val height = bitmap.height
                
                // 创建结果数组: [width, height, pixels...]
                val result = IntArray(2 + width * height)
                result[0] = width
                result[1] = height
                
                // 获取像素数据 (ARGB_8888 格式)
                bitmap.getPixels(result, 2, width, 0, 0, width, height)
                
                bitmap.recycle()
                Log.i(TAG, "Texture loaded: ${width}x${height}")
                result
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading texture: $path", e)
            null
        }
    }
}
