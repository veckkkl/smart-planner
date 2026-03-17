package com.example.smartplannercompose

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale

private const val DEFAULT_NEWS_API_KEY = "AUqBpLx688EFeAUoksb7lS3rAS28MDUDlAsYfJWQZ6UV2rjP"

class NewsRepository(
    private val apiKey: String = DEFAULT_NEWS_API_KEY,
    private val networkClient: NewsNetworkClient = NewsNetworkClient()
) {

    fun fetchTopStories(): Result<List<NewsArticle>> {
        return runCatching {
            val result = networkClient.getTopStories(apiKey)
            if (result.code !in 200..299) {
                throw IllegalStateException("Ошибка сервера ${result.code}")
            }

            val root = JSONObject(result.body)
            val status = root.optString("status")
            if (status.equals("OK", ignoreCase = true).not()) {
                throw IllegalStateException("Статус NYTimes: $status")
            }

            val items = root.optJSONArray("results")
            val mapped = mutableListOf<NewsArticle>()

            if (items != null) {
                for (i in 0 until items.length()) {
                    val obj = items.optJSONObject(i) ?: continue
                    val title = obj.optString("title").trim()
                    val publishedDateRaw = obj.optString("published_date")
                    val publishedAtMillis = parsePublishedDateMillis(publishedDateRaw)

                    if (title.isEmpty() || publishedAtMillis == null) {
                        continue
                    }

                    val abstract = obj.optString("abstract").trim()
                    val source = obj.optString("source").trim().ifEmpty { "NYTimes" }
                    val imageUrl = extractPreferredImageUrl(obj)

                    val id = obj.optString("url").ifBlank { "$title-$publishedDateRaw" }

                    mapped += NewsArticle(
                        id = id,
                        title = title,
                        abstract = abstract,
                        source = source,
                        publishedAtMillis = publishedAtMillis,
                        imageUrl = imageUrl
                    )
                }
            }

            mapped.sortedByDescending { it.publishedAtMillis }
        }
    }

    fun sendAnalyticsEvent(appVersion: String) {
        runCatching {
            val result = networkClient.postAnalyticsEvent(appVersion)
            println("[AnalyticsRequest] code=${result.code}, body=${result.body}")
        }.onFailure { error ->
            println("[AnalyticsRequest] failure: ${error.localizedMessage}")
        }
    }

    private fun extractPreferredImageUrl(obj: JSONObject): String? {
        val multimedia = obj.optJSONArray("multimedia") ?: return null

        val preferredFormats = listOf(
            "superJumbo",
            "threeByTwoSmallAt2X",
            "mediumThreeByTwo440",
            "Large Thumbnail",
            "Normal"
        )

        for (format in preferredFormats) {
            for (i in 0 until multimedia.length()) {
                val item = multimedia.optJSONObject(i) ?: continue
                if (item.optString("format") == format) {
                    val url = item.optString("url")
                    if (url.isNotBlank()) return url
                }
            }
        }

        var bestUrl: String? = null
        var bestWidth = -1
        for (i in 0 until multimedia.length()) {
            val item = multimedia.optJSONObject(i) ?: continue
            val width = item.optInt("width", -1)
            val url = item.optString("url")
            if (url.isNotBlank() && width > bestWidth) {
                bestWidth = width
                bestUrl = url
            }
        }

        return bestUrl
    }

    private fun parsePublishedDateMillis(raw: String): Long? {
        if (raw.isBlank()) return null

        val formatterWithZone = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US)
        val formatterWithoutZone = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX", Locale.US)

        return runCatching {
            formatterWithZone.parse(raw)?.time ?: formatterWithoutZone.parse(raw)?.time
        }.getOrNull()
    }
}
