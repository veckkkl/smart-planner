package com.example.smartplannercompose.domain.dashboard

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskPriority
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Test

class DashboardStatisticsServiceTest {

    private val now = 1_700_000_000_000L
    private val service = DefaultDashboardStatisticsService(
        clock = Clock { now },
        timeZone = TimeZone.getTimeZone("UTC")
    )

    private fun task(
        id: String,
        deadline: Long?,
        completed: Boolean = false,
        priority: TaskPriority = TaskPriority.MEDIUM,
        createdAt: Long = now
    ) = Task(id, createdAt, id, null, priority, false, deadline, completed)

    @Test
    fun `statistics counts completed active overdue and noDate`() {
        val day = 24L * 60 * 60 * 1000
        val tasks = listOf(
            task("done", deadline = now + day, completed = true),
            task("active", deadline = now + day),
            task("overdue", deadline = now - day),
            task("noDate", deadline = null)
        )
        val stats = service.statistics(tasks, DashboardPeriod.ALL_TIME)
        assertEquals(4, stats.total)
        assertEquals(1, stats.completed)
        assertEquals(1, stats.active)
        assertEquals(1, stats.overdue)
        assertEquals(1, stats.withoutDate)
    }

    @Test
    fun `upcoming respects limit and excludes completed`() {
        val day = 24L * 60 * 60 * 1000
        val tasks = listOf(
            task("a", deadline = now + day),
            task("b", deadline = now + 2 * day),
            task("c", deadline = now + 3 * day, completed = true),
            task("d", deadline = now + 4 * day)
        )
        val result = service.upcoming(tasks, limit = 2)
        assertEquals(listOf("a", "b"), result.map { it.id })
    }

    @Test
    fun `tasksByDay groups by startOfDay`() {
        val day = 24L * 60 * 60 * 1000
        val tasks = listOf(
            task("a", deadline = now),
            task("b", deadline = now + 60_000),
            task("c", deadline = now + day),
            task("nd", deadline = null)
        )
        val map = service.tasksByDay(tasks)
        assertEquals(2, map.size)
        val today = service.startOfDay(now)
        assertEquals(listOf("a", "b"), map[today]?.map { it.id })
    }
}
