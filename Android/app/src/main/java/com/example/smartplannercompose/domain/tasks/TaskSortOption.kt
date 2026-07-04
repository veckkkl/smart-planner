package com.example.smartplannercompose.domain.tasks

enum class TaskSortOption(val title: String) {
    DATE_NEWEST("Сначала новые"),
    DATE_OLDEST("Сначала старые"),
    PRIORITY_HIGH_FIRST("Сначала сложные"),
    PRIORITY_LOW_FIRST("Сначала лёгкие")
}
