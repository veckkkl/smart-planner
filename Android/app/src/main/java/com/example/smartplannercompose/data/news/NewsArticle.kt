package com.example.smartplannercompose.data.news

data class NewsArticle(
    val id: String,
    val title: String,
    val abstract: String,
    val source: String,
    val publishedAtMillis: Long,
    val imageUrl: String?
)
