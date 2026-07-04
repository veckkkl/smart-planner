package com.example.smartplannercompose.data.news

import android.content.Context
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File

data class CachedNews(
    val articles: List<NewsArticle>,
    val timestamp: Long
)

interface NewsCache {
    suspend fun save(articles: List<NewsArticle>)
    suspend fun load(): CachedNews?
    val softTtlMs: Long
}

class FileNewsCache(
    context: Context,
    private val gson: Gson = Gson(),
    override val softTtlMs: Long = SOFT_TTL_MS,
    private val hardTtlMs: Long = HARD_TTL_MS
) : NewsCache {

    private val cacheFile = File(context.applicationContext.cacheDir, FILE_NAME)
    private val mutex = Mutex()

    override suspend fun save(articles: List<NewsArticle>) {
        withContext(Dispatchers.IO) {
            mutex.withLock {
                runCatching {
                    cacheFile.parentFile?.mkdirs()
                    val payload = CachedNews(articles, System.currentTimeMillis())
                    cacheFile.writeText(gson.toJson(payload))
                }
            }
        }
    }

    override suspend fun load(): CachedNews? = withContext(Dispatchers.IO) {
        mutex.withLock {
            if (!cacheFile.exists()) return@withLock null
            val cached = runCatching {
                gson.fromJson(cacheFile.readText(), CachedNews::class.java)
            }.getOrNull()
            if (cached == null || cached.timestamp <= 0L) {
                cacheFile.delete(); return@withLock null
            }
            val age = System.currentTimeMillis() - cached.timestamp
            if (age > hardTtlMs) { cacheFile.delete(); return@withLock null }
            cached
        }
    }

    companion object {
        const val SOFT_TTL_MS = 2 * 60 * 1000L
        const val HARD_TTL_MS = 24 * 60 * 60 * 1000L
        private const val FILE_NAME = "news_cache.json"
    }
}
