package com.example.smartplannercompose.presentation.tasks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.smartplannercompose.domain.tasks.CreateTaskError
import com.example.smartplannercompose.domain.tasks.CreateTaskInput
import com.example.smartplannercompose.domain.tasks.CreateTaskUseCase
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskFilter
import com.example.smartplannercompose.domain.tasks.TaskListProcessor
import com.example.smartplannercompose.domain.tasks.TaskRepository
import com.example.smartplannercompose.domain.tasks.TaskSectionResult
import com.example.smartplannercompose.domain.tasks.TaskSortOption
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

data class TasksUiState(
    val sections: List<TaskSectionResult> = emptyList(),
    val filter: TaskFilter = TaskFilter.ALL,
    val sort: TaskSortOption = TaskSortOption.DATE_NEWEST,
    val isEmpty: Boolean = true
)

sealed interface CreateTaskOutcome {
    data class Created(val task: Task) : CreateTaskOutcome
    data object InvalidTitle : CreateTaskOutcome
}

class TasksViewModel(
    private val repository: TaskRepository,
    private val processor: TaskListProcessor,
    private val createTaskUseCase: CreateTaskUseCase
) : ViewModel() {

    private val filter = MutableStateFlow(TaskFilter.ALL)
    private val sort = MutableStateFlow(TaskSortOption.DATE_NEWEST)

    private val _uiState = MutableStateFlow(TasksUiState())
    val uiState: StateFlow<TasksUiState> = _uiState.asStateFlow()

    init {
        combine(repository.observeTasks(), filter, sort) { tasks, f, s ->
            TasksUiState(
                sections = processor.process(tasks, f, s),
                filter = f,
                sort = s,
                isEmpty = tasks.isEmpty()
            )
        }.onEach { _uiState.value = it }
            .launchIn(viewModelScope)
    }

    fun setFilter(value: TaskFilter) { filter.value = value }
    fun setSort(value: TaskSortOption) { sort.value = value }

    fun toggleCompleted(task: Task) {
        repository.update(task.copy(isCompleted = !task.isCompleted))
    }

    fun createTask(input: CreateTaskInput): CreateTaskOutcome {
        val result = createTaskUseCase.execute(input)
        return result.fold(
            onSuccess = { CreateTaskOutcome.Created(it) },
            onFailure = {
                when (it) {
                    is CreateTaskError.InvalidTitle -> CreateTaskOutcome.InvalidTitle
                    else -> CreateTaskOutcome.InvalidTitle
                }
            }
        )
    }
}
