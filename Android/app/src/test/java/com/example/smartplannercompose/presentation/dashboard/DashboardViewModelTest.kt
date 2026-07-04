package com.example.smartplannercompose.presentation.dashboard

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.data.tasks.InMemoryTaskStore
import com.example.smartplannercompose.data.tasks.LocalTaskRepository
import com.example.smartplannercompose.domain.dashboard.DashboardPeriod
import com.example.smartplannercompose.domain.dashboard.DefaultDashboardStatisticsService
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskPriority
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DashboardViewModelTest {

    private val now = 1_700_000_000_000L
    private val clock = Clock { now }

    @Before fun setUp() { Dispatchers.setMain(UnconfinedTestDispatcher()) }
    @After fun tearDown() { Dispatchers.resetMain() }

    private fun seed(): LocalTaskRepository {
        val day = 24L * 60 * 60 * 1000
        val tasks = listOf(
            Task("a", now, "Active", null, TaskPriority.LOW, false, now + day, false),
            Task("b", now, "Overdue", null, TaskPriority.HIGH, false, now - day, false),
            Task("c", now, "Done", null, TaskPriority.LOW, false, now + day, true)
        )
        return LocalTaskRepository(InMemoryTaskStore(tasks))
    }

    @Test
    fun `state reflects repository tasks`() = runTest {
        val repo = seed()
        val vm = DashboardViewModel(
            repository = repo,
            service = DefaultDashboardStatisticsService(clock),
            clock = clock
        )
        val state = vm.uiState.value
        assertEquals(true, state.hasAnyTasks)
        assertEquals(3, state.statistics.total)
        assertEquals(1, state.statistics.completed)
        assertEquals(1, state.statistics.active)
        assertEquals(1, state.statistics.overdue)
    }

    @Test
    fun `setPeriod recomputes`() = runTest {
        val repo = seed()
        val vm = DashboardViewModel(repo, DefaultDashboardStatisticsService(clock), clock)
        vm.setPeriod(DashboardPeriod.ALL_TIME)
        assertEquals(DashboardPeriod.ALL_TIME, vm.uiState.value.period)
    }

    @Test
    fun `marker returns non-null for day with tasks`() = runTest {
        val repo = seed()
        val vm = DashboardViewModel(repo, DefaultDashboardStatisticsService(clock), clock)
        val day = 24L * 60 * 60 * 1000
        val marker = vm.marker(now + day)
        assertNotNull(marker)
    }
}
