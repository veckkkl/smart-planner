package com.example.smartplannercompose.domain.dashboard

import com.example.smartplannercompose.domain.tasks.TaskPriority

data class DashboardStatistics(
    val total: Int,
    val completed: Int,
    val active: Int,
    val overdue: Int,
    val withoutDate: Int,
    val byPriority: Map<TaskPriority, Int>
) {
    companion object {
        val EMPTY = DashboardStatistics(
            total = 0,
            completed = 0,
            active = 0,
            overdue = 0,
            withoutDate = 0,
            byPriority = TaskPriority.values().associateWith { 0 }
        )
    }
}

data class DayMarker(
    val hasActive: Boolean,
    val hasCompleted: Boolean,
    val hasOverdue: Boolean
)
