package com.example.smartplannercompose.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.smartplannercompose.domain.dashboard.DashboardPeriod
import com.example.smartplannercompose.domain.dashboard.DashboardStatistics
import com.example.smartplannercompose.domain.dashboard.DashboardStatisticsService
import com.example.smartplannercompose.domain.dashboard.DayMarker
import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.core.SystemClock
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

data class DashboardUiState(
    val statistics: DashboardStatistics = DashboardStatistics.EMPTY,
    val upcoming: List<Task> = emptyList(),
    val period: DashboardPeriod = DashboardPeriod.WEEK,
    val hasAnyTasks: Boolean = false,
    val tasksByDay: Map<Long, List<Task>> = emptyMap()
)

class DashboardViewModel(
    private val repository: TaskRepository,
    private val service: DashboardStatisticsService,
    private val clock: Clock = SystemClock,
    private val upcomingLimit: Int = DEFAULT_UPCOMING_LIMIT
) : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    private var allTasks: List<Task> = emptyList()
    private var period: DashboardPeriod = DashboardPeriod.WEEK

    init {
        repository.observeTasks()
            .onEach { tasks ->
                allTasks = tasks
                recompute()
            }
            .launchIn(viewModelScope)
    }

    fun setPeriod(value: DashboardPeriod) {
        period = value
        recompute()
    }

    fun toggleCompletion(taskId: String) {
        val task = allTasks.firstOrNull { it.id == taskId } ?: return
        repository.update(task.copy(isCompleted = !task.isCompleted))
    }

    fun tasksOn(dayMillis: Long): List<Task> =
        service.tasks(dayMillis, allTasks)

    fun marker(dayMillis: Long): DayMarker? {
        val key = service.startOfDay(dayMillis)
        val tasks = _uiState.value.tasksByDay[key] ?: return null
        val now = clock.nowMillis()
        var hasActive = false
        var hasCompleted = false
        var hasOverdue = false
        for (task in tasks) {
            if (task.isCompleted) hasCompleted = true
            else if (task.deadlineMillis != null && task.deadlineMillis < now) hasOverdue = true
            else hasActive = true
        }
        return DayMarker(hasActive, hasCompleted, hasOverdue)
    }

    private fun recompute() {
        _uiState.value = DashboardUiState(
            statistics = service.statistics(allTasks, period),
            upcoming = service.upcoming(allTasks, upcomingLimit),
            period = period,
            hasAnyTasks = allTasks.isNotEmpty(),
            tasksByDay = service.tasksByDay(allTasks)
        )
    }

    companion object {
        const val DEFAULT_UPCOMING_LIMIT = 5
    }
}
