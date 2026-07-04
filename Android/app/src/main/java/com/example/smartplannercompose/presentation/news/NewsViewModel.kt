package com.example.smartplannercompose.presentation.news

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.smartplannercompose.data.news.NewsArticle
import com.example.smartplannercompose.data.news.NewsCache
import com.example.smartplannercompose.data.news.NewsRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface NewsUiState {
    data object Loading : NewsUiState
    data class Loaded(val articles: List<NewsArticle>) : NewsUiState
    data object Empty : NewsUiState
    data class Error(val message: String) : NewsUiState
}

class NewsViewModel(
    private val repository: NewsRepository,
    private val cache: NewsCache,
    private val appVersion: String = "1.0"
) : ViewModel() {

    private val _uiState = MutableStateFlow<NewsUiState>(NewsUiState.Loading)
    val uiState: StateFlow<NewsUiState> = _uiState.asStateFlow()

    private var refreshJob: Job? = null
    private var autoRefreshStarted = false

    init {
        loadNews(showLoadingWhenNoCache = true)
        viewModelScope.launch { repository.sendAnalytics(appVersion) }
    }

    fun retry() = loadNews(showLoadingWhenNoCache = true)

    private fun loadNews(showLoadingWhenNoCache: Boolean) {
        viewModelScope.launch {
            val cached = repository.cached()
            val hasCached = !cached.isNullOrEmpty()
            if (hasCached) {
                _uiState.value = NewsUiState.Loaded(cached!!)
                startAutoRefreshIfNeeded()
            } else if (showLoadingWhenNoCache) {
                _uiState.value = NewsUiState.Loading
            }

            runCatching { repository.fetch() }
                .onSuccess { list ->
                    if (list.isEmpty()) _uiState.value = NewsUiState.Empty
                    else {
                        _uiState.value = NewsUiState.Loaded(list)
                        startAutoRefreshIfNeeded()
                    }
                }
                .onFailure { error ->
                    if (!hasCached) {
                        _uiState.value = NewsUiState.Error(
                            error.localizedMessage ?: "Не удалось загрузить новости"
                        )
                    }
                }
        }
    }

    private fun startAutoRefreshIfNeeded() {
        if (autoRefreshStarted) return
        autoRefreshStarted = true
        refreshJob = viewModelScope.launch {
            while (true) {
                delay(cache.softTtlMs)
                loadNews(showLoadingWhenNoCache = false)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        refreshJob?.cancel()
    }
}
