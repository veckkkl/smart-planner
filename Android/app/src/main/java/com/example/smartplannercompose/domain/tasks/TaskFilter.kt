package com.example.smartplannercompose.domain.tasks

enum class TaskFilter(val title: String) {
    ALL("Все"),
    TODAY("Сегодня"),
    UPCOMING("Ближайшие")
}

enum class TaskListSection(val title: String) {
    FLAT(""),
    THIS_WEEK("Эта неделя"),
    THIS_MONTH("Этот месяц")
}

data class TaskSectionResult(
    val section: TaskListSection,
    val tasks: List<Task>
)
