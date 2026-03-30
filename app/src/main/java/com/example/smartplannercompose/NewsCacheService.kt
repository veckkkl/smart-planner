package com.example.smartplannercompose

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

class NewsCacheService(context: Context) {

    private val appContext = context.applicationContext
    private val gson = Gson()
    private val cacheFile = File(appContext.cacheDir, CACHE_FILE_NAME)
    private val cacheMutex = Mutex()

    suspend fun saveNews(news: List<NewsArticle>) {
        withContext(Dispatchers.IO) {
            cacheMutex.withLock {
                runCatching {
                    cacheFile.parentFile?.mkdirs()
                    val payload = CachedNews(
                        articles = news,
                        timestamp = System.currentTimeMillis()
                    )
                    cacheFile.writeText(gson.toJson(payload))
                }
            }
        }
    }

    suspend fun loadNews(): CachedNews? {
        return withContext(Dispatchers.IO) {
            cacheMutex.withLock {
                if (!cacheFile.exists()) {
                    return@withLock null
                }

                val cached = runCatching {
                    gson.fromJson(cacheFile.readText(), CachedNews::class.java)
                }.getOrNull()

                if (cached == null || cached.timestamp <= 0L) {
                    deleteCache()
                    return@withLock null
                }

                val age = System.currentTimeMillis() - cached.timestamp
                if (age > HARD_TTL_MS) {
                    deleteCache()
                    return@withLock null
                }

                cached
            }
        }
    }

    private fun deleteCache() {
        if (cacheFile.exists()) {
            cacheFile.delete()
        }
    }

    companion object {
        const val SOFT_TTL_MS = 2 * 60 * 1000L
        const val HARD_TTL_MS = 24 * 60 * 60 * 1000L
        private const val CACHE_FILE_NAME = "news_cache.json"
    }
}
