package com.example.smartplannercompose

import org.json.JSONObject
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

private const val NY_TIMES_BASE_URL = "https://api.nytimes.com"
private const val TOP_STORIES_PATH = "/svc/topstories/v2/home.json"
private const val ANALYTICS_URL = "https://jsonplaceholder.typicode.com/posts"

data class HttpResult(
    val code: Int,
    val body: String
)

class NewsNetworkClient {

    fun getTopStories(apiKey: String): HttpResult {
        val url = "$NY_TIMES_BASE_URL$TOP_STORIES_PATH?api-key=$apiKey"
        val headers = mapOf(
            "Accept" to "application/json",
            "api-key" to apiKey
        )
        return get(url, headers)
    }

    fun postAnalyticsEvent(appVersion: String): HttpResult {
        val payload = JSONObject()
            .put("title", "news_feed_opened")
            .put("body", "News screen requested NYTimes top stories")
            .put("userId", 42)
            .put("appVersion", appVersion)
            .put("timestamp", System.currentTimeMillis())
            .toString()

        val headers = mapOf(
            "Content-Type" to "application/json; charset=utf-8",
            "Accept" to "application/json",
            "X-App-Platform" to "Android"
        )

        return post(ANALYTICS_URL, headers, payload)
    }

    private fun get(
        urlString: String,
        headers: Map<String, String>
    ): HttpResult {
        val connection = (URL(urlString).openConnection() as HttpURLConnection)
        connection.requestMethod = "GET"
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        headers.forEach { (key, value) ->
            connection.setRequestProperty(key, value)
        }

        return readResponse(connection)
    }

    private fun post(
        urlString: String,
        headers: Map<String, String>,
        jsonBody: String
    ): HttpResult {
        val connection = (URL(urlString).openConnection() as HttpURLConnection)
        connection.requestMethod = "POST"
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        connection.doOutput = true
        headers.forEach { (key, value) ->
            connection.setRequestProperty(key, value)
        }

        BufferedWriter(OutputStreamWriter(connection.outputStream)).use { writer ->
            writer.write(jsonBody)
            writer.flush()
        }

        return readResponse(connection)
    }

    private fun readResponse(connection: HttpURLConnection): HttpResult {
        return try {
            val code = connection.responseCode
            val stream = if (code in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream ?: connection.inputStream
            }

            val body = stream.bufferedReader().use(BufferedReader::readText)
            HttpResult(code = code, body = body)
        } finally {
            connection.disconnect()
        }
    }
}
