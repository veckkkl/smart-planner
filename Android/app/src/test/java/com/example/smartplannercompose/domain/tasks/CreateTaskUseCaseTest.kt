package com.example.smartplannercompose.domain.tasks

import com.example.smartplannercompose.data.tasks.InMemoryTaskStore
import com.example.smartplannercompose.data.tasks.LocalTaskRepository
import com.example.smartplannercompose.core.Clock
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CreateTaskUseCaseTest {

    private val fixedClock = Clock { 1_700_000_000_000L }
    private val repository = LocalTaskRepository(InMemoryTaskStore())
    private val useCase = DefaultCreateTaskUseCase(
        validator = DefaultTaskValidator(),
        repository = repository,
        clock = fixedClock
    )

    @Test
    fun `invalid title returns failure`() {
        val result = useCase.execute(
            CreateTaskInput("   ", null, TaskPriority.LOW, false, null)
        )
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is CreateTaskError.InvalidTitle)
    }

    @Test
    fun `valid input persists task`() {
        val result = useCase.execute(
            CreateTaskInput("  Купить молоко  ", "  скидка  ", TaskPriority.HIGH, true, 123L)
        )
        val task = result.getOrThrow()
        assertEquals("Купить молоко", task.title)
        assertEquals("скидка", task.details)
        assertEquals(TaskPriority.HIGH, task.priority)
        assertEquals(true, task.isFlagged)
        assertEquals(123L, task.deadlineMillis)
        assertEquals(1_700_000_000_000L, task.createdAtMillis)
        assertEquals(listOf(task), repository.currentSnapshot())
    }
}
