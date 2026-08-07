package com.example.smartplannercompose

data class NewsArticle(
    val id: String,
    val title: String,
    val abstract: String,
    val source: String,
    val publishedAtMillis: Long,
    val imageUrl: String?
)

sealed interface NewsUiState {
    data object Loading : NewsUiState
    data class Loaded(val articles: List<NewsArticle>) : NewsUiState
    data object Empty : NewsUiState
    data class Error(val message: String) : NewsUiState
}
