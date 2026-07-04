package com.example.smartplannercompose.domain.tasks

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.core.SystemClock
import java.util.Calendar
import java.util.TimeZone

interface TaskListProcessor {
    fun process(
        tasks: List<Task>,
        filter: TaskFilter,
        sort: TaskSortOption
    ): List<TaskSectionResult>
}

class DefaultTaskListProcessor(
    private val clock: Clock = SystemClock,
    private val timeZone: TimeZone = TimeZone.getDefault()
) : TaskListProcessor {

    private companion object {
        const val WEEK_HORIZON_DAYS = 7
    }

    override fun process(
        tasks: List<Task>,
        filter: TaskFilter,
        sort: TaskSortOption
    ): List<TaskSectionResult> {
        val prefiltered = applyPrimary(tasks, filter)
        return when (filter) {
            TaskFilter.UPCOMING -> groupedUpcoming(prefiltered, sort)
            TaskFilter.ALL, TaskFilter.TODAY ->
                listOf(TaskSectionResult(TaskListSection.FLAT, sorted(prefiltered, sort)))
        }
    }

    private fun applyPrimary(tasks: List<Task>, filter: TaskFilter): List<Task> {
        val now = clock.nowMillis()
        return when (filter) {
            TaskFilter.ALL -> tasks
            TaskFilter.TODAY -> tasks.filter { task ->
                task.deadlineMillis != null && isSameDay(task.deadlineMillis, now)
            }
            TaskFilter.UPCOMING -> tasks.filter { task ->
                !task.isCompleted && task.deadlineMillis != null && task.deadlineMillis >= now
            }
        }
    }

    private fun groupedUpcoming(
        tasks: List<Task>,
        sort: TaskSortOption
    ): List<TaskSectionResult> {
        val now = clock.nowMillis()
        val weekEnd = now + WEEK_HORIZON_DAYS * MILLIS_IN_DAY
        val monthRange = monthRangeContaining(now)

        val weekly = mutableListOf<Task>()
        val monthly = mutableListOf<Task>()

        for (task in tasks) {
            val deadline = task.deadlineMillis ?: continue
            if (deadline <= weekEnd) {
                weekly += task
            } else if (deadline in monthRange) {
                monthly += task
            }
        }

        return buildList {
            if (weekly.isNotEmpty()) {
                add(TaskSectionResult(TaskListSection.THIS_WEEK, sorted(weekly, sort)))
            }
            if (monthly.isNotEmpty()) {
                add(TaskSectionResult(TaskListSection.THIS_MONTH, sorted(monthly, sort)))
            }
        }
    }

    private fun sorted(tasks: List<Task>, sort: TaskSortOption): List<Task> = when (sort) {
        TaskSortOption.DATE_NEWEST ->
            tasks.sortedByDescending { it.deadlineMillis ?: it.createdAtMillis }
        TaskSortOption.DATE_OLDEST ->
            tasks.sortedBy { it.deadlineMillis ?: it.createdAtMillis }
        TaskSortOption.PRIORITY_HIGH_FIRST ->
            tasks.sortedByDescending { it.priority.weight }
        TaskSortOption.PRIORITY_LOW_FIRST ->
            tasks.sortedBy { it.priority.weight }
    }

    private fun isSameDay(a: Long, b: Long): Boolean {
        val ca = calendarAt(a)
        val cb = calendarAt(b)
        return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) &&
            ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
    }

    private fun monthRangeContaining(millis: Long): LongRange {
        val c = calendarAt(millis)
        c.set(Calendar.DAY_OF_MONTH, c.getActualMinimum(Calendar.DAY_OF_MONTH))
        c.set(Calendar.HOUR_OF_DAY, 0); c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0)
        val start = c.timeInMillis
        c.add(Calendar.MONTH, 1)
        val end = c.timeInMillis - 1
        return start..end
    }

    private fun calendarAt(millis: Long): Calendar {
        val c = Calendar.getInstance(timeZone)
        c.timeInMillis = millis
        return c
    }
}

private const val MILLIS_IN_DAY = 24L * 60 * 60 * 1000
