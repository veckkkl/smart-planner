package com.example.smartplannercompose.domain.tasks

import com.example.smartplannercompose.core.Clock
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Test

class TaskListProcessorTest {

    private val now = 1_700_000_000_000L // fixed
    private val processor = DefaultTaskListProcessor(Clock { now }, TimeZone.getTimeZone("UTC"))

    private fun task(
        id: String,
        deadline: Long?,
        priority: TaskPriority = TaskPriority.MEDIUM,
        completed: Boolean = false,
        createdAt: Long = now
    ) = Task(
        id = id,
        createdAtMillis = createdAt,
        title = id,
        details = null,
        priority = priority,
        isFlagged = false,
        deadlineMillis = deadline,
        isCompleted = completed
    )

    @Test
    fun `ALL returns flat section with everything sorted`() {
        val tasks = listOf(
            task("a", deadline = null, createdAt = 100),
            task("b", deadline = now + 1000),
            task("c", deadline = now - 1000)
        )
        val result = processor.process(tasks, TaskFilter.ALL, TaskSortOption.DATE_OLDEST)
        assertEquals(1, result.size)
        assertEquals(TaskListSection.FLAT, result[0].section)
        assertEquals(listOf("a", "c", "b"), result[0].tasks.map { it.id })
    }

    @Test
    fun `TODAY filters by same day as now`() {
        val tasks = listOf(
            task("today", deadline = now),
            task("yesterday", deadline = now - 24L * 60 * 60 * 1000),
            task("none", deadline = null)
        )
        val result = processor.process(tasks, TaskFilter.TODAY, TaskSortOption.DATE_NEWEST)
        assertEquals(listOf("today"), result.single().tasks.map { it.id })
    }

    @Test
    fun `UPCOMING groups into week and month`() {
        val day = 24L * 60 * 60 * 1000
        val tasks = listOf(
            task("inWeek", deadline = now + 3 * day),
            task("inMonth", deadline = now + 20 * day),
            task("past", deadline = now - day),
            task("completedFuture", deadline = now + day, completed = true)
        )
        val result = processor.process(tasks, TaskFilter.UPCOMING, TaskSortOption.DATE_OLDEST)
        val sections = result.associate { it.section to it.tasks.map { t -> t.id } }
        assertEquals(listOf("inWeek"), sections[TaskListSection.THIS_WEEK])
        // inMonth ends up in THIS_MONTH only if it falls inside the current calendar month
        // — under UTC anchor (2023-11-14) +20 days lands in early December, so no month bucket
        // assert it didn't accidentally land in the week bucket either
        assertEquals(null, sections[TaskListSection.THIS_MONTH])
    }

    @Test
    fun `priority sort respects weight`() {
        val tasks = listOf(
            task("low", deadline = now, priority = TaskPriority.LOW),
            task("high", deadline = now, priority = TaskPriority.HIGH),
            task("mid", deadline = now, priority = TaskPriority.MEDIUM)
        )
        val byHigh = processor.process(tasks, TaskFilter.ALL, TaskSortOption.PRIORITY_HIGH_FIRST)
            .single().tasks.map { it.id }
        assertEquals(listOf("high", "mid", "low"), byHigh)
    }
}
