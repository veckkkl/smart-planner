package com.example.smartplannercompose.data.news

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

interface ImageCache {
    suspend fun loadImage(url: String): Bitmap?
}

class FileImageCache private constructor(context: Context) : ImageCache {

    private val cacheDir = File(context.applicationContext.cacheDir, IMAGE_CACHE_DIR).apply { mkdirs() }
    private val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val diskMutex = Mutex()

    private val memoryCache = object : LruCache<String, Bitmap>(memoryCacheSizeKb()) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount / 1024
    }

    init { ioScope.launch { cleanupOldFiles() } }

    override suspend fun loadImage(url: String): Bitmap? {
        if (url.isBlank()) return null
        memoryCache.get(url)?.let { return it }
        return withContext(Dispatchers.IO) {
            memoryCache.get(url)?.let { return@withContext it }
            loadFromDisk(url)?.let { bitmap ->
                memoryCache.put(url, bitmap)
                return@withContext bitmap
            }
            val downloaded = downloadFromNetwork(url) ?: return@withContext null
            memoryCache.put(url, downloaded)
            saveToDisk(url, downloaded)
            downloaded
        }
    }

    private suspend fun loadFromDisk(url: String): Bitmap? = diskMutex.withLock {
        val file = fileForUrl(url)
        if (!file.exists()) return@withLock null
        val bitmap = runCatching { BitmapFactory.decodeFile(file.absolutePath) }.getOrNull()
        if (bitmap == null) { file.delete(); null } else bitmap
    }

    private suspend fun saveToDisk(url: String, bitmap: Bitmap) {
        diskMutex.withLock {
            runCatching {
                fileForUrl(url).outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            }
        }
    }

    private suspend fun cleanupOldFiles() {
        diskMutex.withLock {
            val now = System.currentTimeMillis()
            cacheDir.listFiles()?.forEach { file ->
                if (now - file.lastModified() > IMAGE_FILE_TTL_MS) file.delete()
            }
        }
    }

    private fun downloadFromNetwork(url: String): Bitmap? = runCatching {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15_000; readTimeout = 15_000
        }
        try {
            connection.connect()
            if (connection.responseCode !in 200..299) return@runCatching null
            connection.inputStream.use { BitmapFactory.decodeStream(it) }
        } finally { connection.disconnect() }
    }.getOrNull()

    private fun fileForUrl(url: String): File = File(cacheDir, sha256(url))

    private fun sha256(text: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }

    companion object {
        private const val IMAGE_CACHE_DIR = "news_images"
        private const val IMAGE_FILE_TTL_MS = 7 * 24 * 60 * 60 * 1000L

        @Volatile private var instance: FileImageCache? = null

        fun getInstance(context: Context): FileImageCache =
            instance ?: synchronized(this) {
                instance ?: FileImageCache(context).also { instance = it }
            }

        private fun memoryCacheSizeKb(): Int {
            val maxKb = (Runtime.getRuntime().maxMemory() / 1024L).toInt()
            return (maxKb / 8).coerceAtLeast(1024)
        }
    }
}
