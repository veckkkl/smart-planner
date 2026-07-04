package com.example.smartplannercompose.data.news

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NewsMapperTest {

    @Test
    fun `parses valid top stories payload`() {
        val body = """
        {
          "status": "OK",
          "results": [
            {
              "title": "Hello",
              "abstract": "World",
              "source": "NYTimes",
              "url": "https://example.com/a",
              "published_date": "2024-01-15T10:00:00+00:00",
              "multimedia": [
                {"format": "superJumbo", "url": "https://img/superjumbo.jpg", "width": 2048}
              ]
            }
          ]
        }
        """.trimIndent()

        val articles = NewsMapper.parseTopStories(body)
        assertEquals(1, articles.size)
        val a = articles.first()
        assertEquals("Hello", a.title)
        assertEquals("World", a.abstract)
        assertEquals("NYTimes", a.source)
        assertEquals("https://img/superjumbo.jpg", a.imageUrl)
    }

    @Test
    fun `falls back to widest multimedia url when preferred format absent`() {
        val body = """
        {
          "status": "OK",
          "results": [
            {
              "title": "T",
              "abstract": "",
              "source": "",
              "url": "https://example.com/b",
              "published_date": "2024-01-15T10:00:00+00:00",
              "multimedia": [
                {"format": "Other", "url": "https://img/small.jpg", "width": 100},
                {"format": "Other", "url": "https://img/large.jpg", "width": 800}
              ]
            }
          ]
        }
        """.trimIndent()

        val a = NewsMapper.parseTopStories(body).single()
        assertEquals("https://img/large.jpg", a.imageUrl)
        assertEquals("NYTimes", a.source) // fallback when empty
    }

    @Test(expected = IllegalStateException::class)
    fun `non-OK status throws`() {
        val body = """{"status": "ERROR", "results": []}"""
        NewsMapper.parseTopStories(body)
    }

    @Test
    fun `entries with empty title or bad date are skipped`() {
        val body = """
        {
          "status": "OK",
          "results": [
            {"title": "", "published_date": "2024-01-15T10:00:00+00:00"},
            {"title": "X", "published_date": ""}
          ]
        }
        """.trimIndent()
        assertTrue(NewsMapper.parseTopStories(body).isEmpty())
    }
}
