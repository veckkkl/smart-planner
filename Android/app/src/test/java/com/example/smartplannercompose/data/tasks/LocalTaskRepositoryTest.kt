package com.example.smartplannercompose.data.tasks

import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskPriority
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class LocalTaskRepositoryTest {

    private fun newTask(id: String) = Task(
        id = id,
        createdAtMillis = 1L,
        title = id,
        details = null,
        priority = TaskPriority.LOW,
        isFlagged = false,
        deadlineMillis = null,
        isCompleted = false
    )

    @Test
    fun `save and observe emits updated list`() = runTest {
        val store = InMemoryTaskStore()
        val repo = LocalTaskRepository(store)
        repo.save(newTask("a"))
        repo.save(newTask("b"))
        assertEquals(listOf("a", "b"), repo.observeTasks().first().map { it.id })
        assertEquals(repo.observeTasks().first(), store.load())
    }

    @Test
    fun `update replaces task by id`() = runTest {
        val repo = LocalTaskRepository(InMemoryTaskStore())
        repo.save(newTask("x"))
        repo.update(newTask("x").copy(title = "renamed"))
        assertEquals("renamed", repo.observeTasks().first().single().title)
    }

    @Test
    fun `delete removes task`() = runTest {
        val repo = LocalTaskRepository(InMemoryTaskStore())
        repo.save(newTask("a"))
        repo.save(newTask("b"))
        repo.delete("a")
        assertEquals(listOf("b"), repo.observeTasks().first().map { it.id })
    }

    @Test
    fun `restores from store on creation`() = runTest {
        val store = InMemoryTaskStore(listOf(newTask("z")))
        val repo = LocalTaskRepository(store)
        assertEquals(listOf("z"), repo.observeTasks().first().map { it.id })
    }
}
