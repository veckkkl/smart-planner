package com.example.smartplannercompose

import android.graphics.Bitmap
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

class ImageLoader(
    private val imageCacheService: ImageCacheService
) {
    suspend fun loadImage(url: String): Bitmap? {
        return imageCacheService.loadImage(url)
    }
}

@Composable
fun rememberImageLoader(): ImageLoader {
    val context = LocalContext.current.applicationContext
    return remember(context) {
        ImageLoader(ImageCacheService.getInstance(context))
    }
}
