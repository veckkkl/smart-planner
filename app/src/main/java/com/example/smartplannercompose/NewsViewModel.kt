package com.example.smartplannercompose

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class NewsViewModel(
    application: Application
) : AndroidViewModel(application) {

    private val repository = NewsRepository(context = application.applicationContext)

    private val _uiState = MutableStateFlow<NewsUiState>(NewsUiState.Loading)
    val uiState: StateFlow<NewsUiState> = _uiState.asStateFlow()

    private var refreshJob: Job? = null
    private var hasStartedAutoRefresh = false

    init {
        loadNews(showLoadingWhenNoCache = true)
        viewModelScope.launch(Dispatchers.IO) {
            repository.sendAnalyticsEvent(appVersion = "1.0")
        }
    }

    fun retry() {
        loadNews(showLoadingWhenNoCache = true)
    }

    private fun loadNews(showLoadingWhenNoCache: Boolean) {
        viewModelScope.launch {
            val cachedNews = repository.getCachedNews()
            val hasCachedNews = !cachedNews.isNullOrEmpty()

            if (hasCachedNews) {
                _uiState.value = NewsUiState.Loaded(cachedNews)
                startAutoRefreshIfNeeded()
            } else if (showLoadingWhenNoCache) {
                _uiState.value = NewsUiState.Loading
            }

            runCatching {
                repository.fetchNews()
            }
                .onSuccess { list ->
                    if (list.isEmpty()) {
                        _uiState.value = NewsUiState.Empty
                    } else {
                        _uiState.value = NewsUiState.Loaded(list)
                        startAutoRefreshIfNeeded()
                    }
                }
                .onFailure { error ->
                    if (!hasCachedNews) {
                        _uiState.value = NewsUiState.Error(
                            error.localizedMessage ?: "Не удалось загрузить новости"
                        )
                    }
                }
        }
    }

    private fun startAutoRefreshIfNeeded() {
        if (hasStartedAutoRefresh) return

        hasStartedAutoRefresh = true
        refreshJob = viewModelScope.launch {
            while (true) {
                delay(NewsCacheService.SOFT_TTL_MS)
                loadNews(showLoadingWhenNoCache = false)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        refreshJob?.cancel()
    }
}
