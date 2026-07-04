package com.example.smartplannercompose.domain.tasks

import java.util.UUID

data class Task(
    val id: String,
    val createdAtMillis: Long,
    val title: String,
    val details: String?,
    val priority: TaskPriority,
    val isFlagged: Boolean,
    val deadlineMillis: Long?,
    val isCompleted: Boolean
) {
    companion object {
        fun create(
            title: String,
            details: String?,
            priority: TaskPriority,
            isFlagged: Boolean,
            deadlineMillis: Long?,
            createdAtMillis: Long,
            id: String = UUID.randomUUID().toString()
        ): Task = Task(
            id = id,
            createdAtMillis = createdAtMillis,
            title = title,
            details = details,
            priority = priority,
            isFlagged = isFlagged,
            deadlineMillis = deadlineMillis,
            isCompleted = false
        )
    }
}
