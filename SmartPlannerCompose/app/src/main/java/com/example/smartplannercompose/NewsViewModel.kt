package com.example.smartplannercompose

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class NewsViewModel(
    private val repository: NewsRepository = NewsRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow<NewsUiState>(NewsUiState.Loading)
    val uiState: StateFlow<NewsUiState> = _uiState.asStateFlow()

    private var refreshJob: Job? = null
    private var hasStartedAutoRefresh = false

    init {
        loadNews(showLoading = true)
        viewModelScope.launch(Dispatchers.IO) {
            repository.sendAnalyticsEvent(appVersion = "1.0")
        }
    }

    fun retry() {
        loadNews(showLoading = true)
    }

    private fun loadNews(showLoading: Boolean) {
        if (showLoading) {
            _uiState.value = NewsUiState.Loading
        }

        viewModelScope.launch {
            val result = withContext(Dispatchers.IO) {
                repository.fetchTopStories()
            }

            result
                .onSuccess { list ->
                    if (list.isEmpty()) {
                        _uiState.value = NewsUiState.Empty
                    } else {
                        _uiState.value = NewsUiState.Loaded(list)
                        startAutoRefreshIfNeeded()
                    }
                }
                .onFailure { error ->
                    _uiState.value = NewsUiState.Error(
                        error.localizedMessage ?: "Не удалось загрузить новости"
                    )
                }
        }
    }

    private fun startAutoRefreshIfNeeded() {
        if (hasStartedAutoRefresh) return

        hasStartedAutoRefresh = true
        refreshJob = viewModelScope.launch {
            while (true) {
                delay(120_000)
                loadNews(showLoading = false)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        refreshJob?.cancel()
    }
}
