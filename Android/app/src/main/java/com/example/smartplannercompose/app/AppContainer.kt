package com.example.smartplannercompose.app

import android.content.Context
import com.example.smartplannercompose.BuildConfig
import com.example.smartplannercompose.core.SystemClock
import com.example.smartplannercompose.data.news.DefaultNewsRepository
import com.example.smartplannercompose.data.news.FileImageCache
import com.example.smartplannercompose.data.news.FileNewsCache
import com.example.smartplannercompose.data.news.NewsApiClient
import com.example.smartplannercompose.data.news.NewsCache
import com.example.smartplannercompose.data.news.NewsRepository
import com.example.smartplannercompose.data.tasks.LocalTaskRepository
import com.example.smartplannercompose.data.tasks.SharedPreferencesTaskStore
import com.example.smartplannercompose.domain.dashboard.DefaultDashboardStatisticsService
import com.example.smartplannercompose.domain.dashboard.DashboardStatisticsService
import com.example.smartplannercompose.domain.tasks.CreateTaskUseCase
import com.example.smartplannercompose.domain.tasks.DefaultCreateTaskUseCase
import com.example.smartplannercompose.domain.tasks.DefaultTaskListProcessor
import com.example.smartplannercompose.domain.tasks.DefaultTaskValidator
import com.example.smartplannercompose.domain.tasks.TaskListProcessor
import com.example.smartplannercompose.domain.tasks.TaskRepository

private const val PREFS_NAME = "SmartPlannerPrefs"
class AppContainer(context: Context) {
    private val appContext = context.applicationContext
    private val preferences = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    val taskRepository: TaskRepository =
        LocalTaskRepository(SharedPreferencesTaskStore(preferences))

    val taskListProcessor: TaskListProcessor = DefaultTaskListProcessor(SystemClock)

    val createTaskUseCase: CreateTaskUseCase = DefaultCreateTaskUseCase(
        validator = DefaultTaskValidator(),
        repository = taskRepository,
        clock = SystemClock
    )

    val dashboardService: DashboardStatisticsService =
        DefaultDashboardStatisticsService(SystemClock)

    val newsCache: NewsCache = FileNewsCache(appContext)

    val newsRepository: NewsRepository = DefaultNewsRepository(
        apiClient = NewsApiClient(),
        cache = newsCache,
        apiKey = BuildConfig.NYT_API_KEY
    )

    val imageCache by lazy { FileImageCache.getInstance(appContext) }
}
