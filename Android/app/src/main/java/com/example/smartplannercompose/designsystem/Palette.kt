package com.example.smartplannercompose.designsystem

import androidx.compose.ui.graphics.Color
import com.example.smartplannercompose.domain.tasks.TaskPriority

object PriorityPalette {
    val low = Color(0xFF4CAF50)
    val medium = Color(0xFFFFC107)
    val high = Color(0xFFF44336)

    fun colorFor(priority: TaskPriority): Color = when (priority) {
        TaskPriority.LOW -> low
        TaskPriority.MEDIUM -> medium
        TaskPriority.HIGH -> high
    }
}

object DashboardPalette {
    val completed = Color(0xFF4CAF50)
    val active = Color(0xFF2196F3)
    val overdue = Color(0xFFF44336)
    val withoutDate = Color(0xFF9E9E9E)
}
