package com.example.smartplannercompose.domain.tasks

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.core.SystemClock

data class CreateTaskInput(
    val title: String,
    val details: String?,
    val priority: TaskPriority,
    val isFlagged: Boolean,
    val deadlineMillis: Long?
)

sealed class CreateTaskError : Throwable() {
    data object InvalidTitle : CreateTaskError()
}

interface CreateTaskUseCase {
    fun execute(input: CreateTaskInput): Result<Task>
}

class DefaultCreateTaskUseCase(
    private val validator: TaskValidator = DefaultTaskValidator(),
    private val repository: TaskRepository,
    private val clock: Clock = SystemClock
) : CreateTaskUseCase {

    override fun execute(input: CreateTaskInput): Result<Task> {
        if (!validator.isValidTitle(input.title)) {
            return Result.failure(CreateTaskError.InvalidTitle)
        }
        val task = Task.create(
            title = input.title.trim(),
            details = validator.sanitize(input.details),
            priority = input.priority,
            isFlagged = input.isFlagged,
            deadlineMillis = input.deadlineMillis,
            createdAtMillis = clock.nowMillis()
        )
        repository.save(task)
        return Result.success(task)
    }
}
