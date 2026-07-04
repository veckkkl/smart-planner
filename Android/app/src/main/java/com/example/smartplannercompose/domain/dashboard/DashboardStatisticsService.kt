package com.example.smartplannercompose.domain.dashboard

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.core.SystemClock
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskPriority
import java.util.Calendar
import java.util.TimeZone

interface DashboardStatisticsService {
    fun statistics(tasks: List<Task>, period: DashboardPeriod): DashboardStatistics
    fun upcoming(tasks: List<Task>, limit: Int): List<Task>
    fun tasksByDay(tasks: List<Task>): Map<Long, List<Task>>
    fun tasks(onDayStartMillis: Long, tasks: List<Task>): List<Task>
    fun startOfDay(millis: Long): Long
}

class DefaultDashboardStatisticsService(
    private val clock: Clock = SystemClock,
    private val timeZone: TimeZone = TimeZone.getDefault()
) : DashboardStatisticsService {

    override fun statistics(tasks: List<Task>, period: DashboardPeriod): DashboardStatistics {
        val now = clock.nowMillis()
        val scoped = tasks.filter { isInPeriod(it, period, now) }

        var completed = 0
        var overdue = 0
        var active = 0
        var noDate = 0
        val byPriority = mutableMapOf<TaskPriority, Int>().apply {
            TaskPriority.values().forEach { put(it, 0) }
        }

        for (task in scoped) {
            byPriority[task.priority] = (byPriority[task.priority] ?: 0) + 1
            if (task.isCompleted) { completed++; continue }
            val deadline = task.deadlineMillis
            if (deadline == null) { noDate++; continue }
            if (deadline < now) overdue++ else active++
        }

        return DashboardStatistics(
            total = scoped.size,
            completed = completed,
            active = active,
            overdue = overdue,
            withoutDate = noDate,
            byPriority = byPriority
        )
    }

    override fun upcoming(tasks: List<Task>, limit: Int): List<Task> {
        val now = clock.nowMillis()
        return tasks
            .asSequence()
            .filter { !it.isCompleted }
            .filter { (it.deadlineMillis ?: now) >= now }
            .sortedBy { it.deadlineMillis ?: Long.MAX_VALUE }
            .take(limit)
            .toList()
    }

    override fun tasksByDay(tasks: List<Task>): Map<Long, List<Task>> {
        val result = HashMap<Long, MutableList<Task>>()
        for (task in tasks) {
            val deadline = task.deadlineMillis ?: continue
            val key = startOfDay(deadline)
            result.getOrPut(key) { mutableListOf() }.add(task)
        }
        return result
    }

    override fun tasks(onDayStartMillis: Long, tasks: List<Task>): List<Task> {
        val target = startOfDay(onDayStartMillis)
        return tasks.filter { task ->
            val d = task.deadlineMillis ?: return@filter false
            startOfDay(d) == target
        }
    }

    override fun startOfDay(millis: Long): Long {
        val c = Calendar.getInstance(timeZone).apply { timeInMillis = millis }
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }

    private fun isInPeriod(task: Task, period: DashboardPeriod, now: Long): Boolean {
        if (period == DashboardPeriod.ALL_TIME) return true
        val reference = task.deadlineMillis ?: task.createdAtMillis
        val nowCal = calendarAt(now)
        val refCal = calendarAt(reference)
        return when (period) {
            DashboardPeriod.WEEK ->
                nowCal.get(Calendar.YEAR) == refCal.get(Calendar.YEAR) &&
                    nowCal.get(Calendar.WEEK_OF_YEAR) == refCal.get(Calendar.WEEK_OF_YEAR)
            DashboardPeriod.MONTH ->
                nowCal.get(Calendar.YEAR) == refCal.get(Calendar.YEAR) &&
                    nowCal.get(Calendar.MONTH) == refCal.get(Calendar.MONTH)
            DashboardPeriod.ALL_TIME -> true
        }
    }

    private fun calendarAt(millis: Long): Calendar =
        Calendar.getInstance(timeZone).apply { timeInMillis = millis }
}
