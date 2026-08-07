package com.example.smartplannercompose

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

class ImageCacheService private constructor(context: Context) {

    private val appContext = context.applicationContext
    private val cacheDir = File(appContext.cacheDir, IMAGE_CACHE_DIR).apply { mkdirs() }
    private val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val diskMutex = Mutex()

    private val memoryCache = object : LruCache<String, Bitmap>(calculateMemoryCacheSizeKb()) {
        override fun sizeOf(key: String, value: Bitmap): Int {
            return value.byteCount / 1024
        }
    }

    init {
        cleanupOldFilesInBackground()
    }

    suspend fun loadImage(url: String): Bitmap? {
        if (url.isBlank()) return null

        memoryCache.get(url)?.let { return it }

        return withContext(Dispatchers.IO) {
            memoryCache.get(url)?.let { return@withContext it }

            val bitmapFromDisk = loadFromDisk(url)
            if (bitmapFromDisk != null) {
                memoryCache.put(url, bitmapFromDisk)
                return@withContext bitmapFromDisk
            }

            val bitmapFromNetwork = downloadFromNetwork(url) ?: return@withContext null
            memoryCache.put(url, bitmapFromNetwork)
            saveToDisk(url, bitmapFromNetwork)
            bitmapFromNetwork
        }
    }

    fun cleanupOldFilesInBackground() {
        ioScope.launch {
            cleanupOldFiles()
        }
    }

    private suspend fun loadFromDisk(url: String): Bitmap? {
        return diskMutex.withLock {
            val file = fileForUrl(url)
            if (!file.exists()) return@withLock null

            val bitmap = runCatching {
                BitmapFactory.decodeFile(file.absolutePath)
            }.getOrNull()

            if (bitmap == null) {
                file.delete()
                return@withLock null
            }

            bitmap
        }
    }

    private suspend fun saveToDisk(url: String, bitmap: Bitmap) {
        diskMutex.withLock {
            val file = fileForUrl(url)
            runCatching {
                file.outputStream().use { output ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                }
            }
        }
    }

    private suspend fun cleanupOldFiles() {
        withContext(Dispatchers.IO) {
            diskMutex.withLock {
                val now = System.currentTimeMillis()
                cacheDir.listFiles()?.forEach { file ->
                    val age = now - file.lastModified()
                    if (age > IMAGE_FILE_TTL_MS) {
                        file.delete()
                    }
                }
            }
        }
    }

    private fun downloadFromNetwork(url: String): Bitmap? {
        return runCatching {
            val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = 15_000
                readTimeout = 15_000
            }

            try {
                connection.connect()
                if (connection.responseCode !in 200..299) {
                    return@runCatching null
                }

                connection.inputStream.use { stream ->
                    BitmapFactory.decodeStream(stream)
                }
            } finally {
                connection.disconnect()
            }
        }.getOrNull()
    }

    private fun fileForUrl(url: String): File {
        return File(cacheDir, sha256(url))
    }

    private fun sha256(text: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(text.toByteArray())
        val builder = StringBuilder(digest.size * 2)
        digest.forEach { byte ->
            builder.append("%02x".format(byte))
        }
        return builder.toString()
    }

    companion object {
        private const val IMAGE_CACHE_DIR = "news_images"
        private const val IMAGE_FILE_TTL_MS = 7 * 24 * 60 * 60 * 1000L

        @Volatile
        private var instance: ImageCacheService? = null

        fun getInstance(context: Context): ImageCacheService {
            return instance ?: synchronized(this) {
                instance ?: ImageCacheService(context).also { instance = it }
            }
        }

        private fun calculateMemoryCacheSizeKb(): Int {
            val maxMemoryKb = (Runtime.getRuntime().maxMemory() / 1024L).toInt()
            return (maxMemoryKb / 8).coerceAtLeast(1024)
        }
    }
}
