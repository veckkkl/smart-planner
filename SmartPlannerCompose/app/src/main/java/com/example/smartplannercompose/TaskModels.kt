package com.example.smartplannercompose

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class TaskPriority(val title: String) {
    LOW("Низкий"),
    MEDIUM("Средний"),
    HIGH("Высокий")
}

data class Task(
    val id: Long = System.currentTimeMillis(),
    val createdAtMillis: Long = System.currentTimeMillis(),
    val title: String,
    val description: String?,
    val priority: TaskPriority,
    val isFlagged: Boolean,
    val deadlineMillis: Long?,
    val isCompleted: Boolean = false
)

enum class SortOption {
    NONE,
    DATE_NEWEST,
    DATE_OLDEST,
    PRIORITY_HIGH_FIRST,
    PRIORITY_LOW_FIRST
}

enum class BottomTab {
    HOME,
    TASKS,
    NOTES
}

fun formatDeadline(deadlineMillis: Long?): String? {
    if (deadlineMillis == null) return null
    val date = Date(deadlineMillis)
    val formatter = SimpleDateFormat("dd.MM HH:mm", Locale.getDefault())
    return formatter.format(date)
}