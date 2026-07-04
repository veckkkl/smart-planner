package com.example.smartplannercompose.data.news

import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale

internal object NewsMapper {

    private val preferredFormats = listOf(
        "superJumbo",
        "threeByTwoSmallAt2X",
        "mediumThreeByTwo440",
        "Large Thumbnail",
        "Normal"
    )

    fun parseTopStories(body: String): List<NewsArticle> {
        val root = JSONObject(body)
        val status = root.optString("status")
        if (!status.equals("OK", ignoreCase = true)) {
            throw IllegalStateException("Статус NYTimes: $status")
        }
        val items = root.optJSONArray("results") ?: return emptyList()
        val articles = mutableListOf<NewsArticle>()
        for (i in 0 until items.length()) {
            val obj = items.optJSONObject(i) ?: continue
            articles.addNullable(map(obj))
        }
        return articles.sortedByDescending { it.publishedAtMillis }
    }

    private fun map(obj: JSONObject): NewsArticle? {
        val title = obj.optString("title").trim()
        val publishedRaw = obj.optString("published_date")
        val publishedAtMillis = parseDateMillis(publishedRaw) ?: return null
        if (title.isEmpty()) return null

        val abstract = obj.optString("abstract").trim()
        val source = obj.optString("source").trim().ifEmpty { "NYTimes" }
        val imageUrl = extractImageUrl(obj.optJSONArray("multimedia"))
        val id = obj.optString("url").ifBlank { "$title-$publishedRaw" }

        return NewsArticle(
            id = id,
            title = title,
            abstract = abstract,
            source = source,
            publishedAtMillis = publishedAtMillis,
            imageUrl = imageUrl
        )
    }

    private fun extractImageUrl(media: JSONArray?): String? {
        if (media == null) return null
        for (format in preferredFormats) {
            for (i in 0 until media.length()) {
                val item = media.optJSONObject(i) ?: continue
                if (item.optString("format") == format) {
                    val url = item.optString("url")
                    if (url.isNotBlank()) return url
                }
            }
        }
        var bestUrl: String? = null
        var bestWidth = -1
        for (i in 0 until media.length()) {
            val item = media.optJSONObject(i) ?: continue
            val width = item.optInt("width", -1)
            val url = item.optString("url")
            if (url.isNotBlank() && width > bestWidth) {
                bestWidth = width
                bestUrl = url
            }
        }
        return bestUrl
    }

    private fun parseDateMillis(raw: String): Long? {
        if (raw.isBlank()) return null
        val withZone = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US)
        val shortZone = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX", Locale.US)
        return runCatching {
            withZone.parse(raw)?.time ?: shortZone.parse(raw)?.time
        }.getOrNull()
    }
}

private fun <T : Any> MutableList<T>.addNullable(value: T?) {
    if (value != null) add(value)
}
