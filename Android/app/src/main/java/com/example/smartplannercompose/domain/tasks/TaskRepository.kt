package com.example.smartplannercompose.domain.tasks

import kotlinx.coroutines.flow.Flow

interface TaskRepository {
    fun observeTasks(): Flow<List<Task>>
    fun currentSnapshot(): List<Task>
    fun save(task: Task)
    fun update(task: Task)
    fun delete(id: String)
}
