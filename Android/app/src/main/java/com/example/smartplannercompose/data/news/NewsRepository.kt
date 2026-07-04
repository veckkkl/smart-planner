package com.example.smartplannercompose.data.news

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

interface NewsRepository {
    suspend fun cached(): List<NewsArticle>?
    suspend fun fetch(): List<NewsArticle>
    suspend fun sendAnalytics(appVersion: String)
}

class DefaultNewsRepository(
    private val apiClient: ApiClient,
    private val cache: NewsCache,
    private val apiKey: String
) : NewsRepository {

    override suspend fun cached(): List<NewsArticle>? = cache.load()?.articles

    override suspend fun fetch(): List<NewsArticle> = withContext(Dispatchers.IO) {
        val result = apiClient.getTopStories(apiKey)
        if (result.code !in 200..299) {
            throw IllegalStateException("Ошибка сервера ${result.code}")
        }
        val articles = NewsMapper.parseTopStories(result.body)
        cache.save(articles)
        articles
    }

    override suspend fun sendAnalytics(appVersion: String) {
        withContext(Dispatchers.IO) {
            runCatching { apiClient.postAnalyticsEvent(appVersion) }
        }
    }
}
