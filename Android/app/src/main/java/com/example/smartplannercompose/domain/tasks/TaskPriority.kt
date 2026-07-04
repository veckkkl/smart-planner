package com.example.smartplannercompose.domain.tasks

enum class TaskPriority(val title: String, val weight: Int) {
    LOW(title = "Низкий", weight = 0),
    MEDIUM(title = "Средний", weight = 1),
    HIGH(title = "Высокий", weight = 2)
}
