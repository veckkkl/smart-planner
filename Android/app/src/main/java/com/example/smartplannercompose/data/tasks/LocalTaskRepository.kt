package com.example.smartplannercompose.data.tasks

import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

class LocalTaskRepository(
    private val store: TaskStore
) : TaskRepository {

    private val state = MutableStateFlow(store.load())

    override fun observeTasks(): Flow<List<Task>> = state.asStateFlow()

    override fun currentSnapshot(): List<Task> = state.value

    override fun save(task: Task) {
        update { it + task }
    }

    override fun update(task: Task) {
        update { tasks ->
            tasks.map { if (it.id == task.id) task else it }
        }
    }

    override fun delete(id: String) {
        update { tasks -> tasks.filterNot { it.id == id } }
    }

    private inline fun update(transform: (List<Task>) -> List<Task>) {
        val next = transform(state.value)
        state.value = next
        store.save(next)
    }
}
