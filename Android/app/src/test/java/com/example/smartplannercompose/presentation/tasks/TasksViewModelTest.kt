package com.example.smartplannercompose.presentation.tasks

import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.data.tasks.InMemoryTaskStore
import com.example.smartplannercompose.data.tasks.LocalTaskRepository
import com.example.smartplannercompose.domain.tasks.CreateTaskInput
import com.example.smartplannercompose.domain.tasks.DefaultCreateTaskUseCase
import com.example.smartplannercompose.domain.tasks.DefaultTaskListProcessor
import com.example.smartplannercompose.domain.tasks.DefaultTaskValidator
import com.example.smartplannercompose.domain.tasks.TaskFilter
import com.example.smartplannercompose.domain.tasks.TaskPriority
import com.example.smartplannercompose.domain.tasks.TaskSortOption
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TasksViewModelTest {

    @Before fun setUp() { Dispatchers.setMain(UnconfinedTestDispatcher()) }
    @After fun tearDown() { Dispatchers.resetMain() }

    private fun newViewModel(): TasksViewModel {
        val repo = LocalTaskRepository(InMemoryTaskStore())
        return TasksViewModel(
            repository = repo,
            processor = DefaultTaskListProcessor(Clock { 0L }),
            createTaskUseCase = DefaultCreateTaskUseCase(
                validator = DefaultTaskValidator(),
                repository = repo,
                clock = Clock { 0L }
            )
        )
    }

    @Test
    fun `initial state is empty`() = runTest {
        val vm = newViewModel()
        assertTrue(vm.uiState.value.isEmpty)
        assertEquals(TaskFilter.ALL, vm.uiState.value.filter)
        assertEquals(TaskSortOption.DATE_NEWEST, vm.uiState.value.sort)
    }

    @Test
    fun `createTask with valid input updates state`() = runTest {
        val vm = newViewModel()
        val outcome = vm.createTask(
            CreateTaskInput("Hello", null, TaskPriority.LOW, false, null)
        )
        assertTrue(outcome is CreateTaskOutcome.Created)
        assertEquals(1, vm.uiState.value.sections.sumOf { it.tasks.size })
        assertEquals(false, vm.uiState.value.isEmpty)
    }

    @Test
    fun `createTask with blank title returns InvalidTitle`() = runTest {
        val vm = newViewModel()
        val outcome = vm.createTask(
            CreateTaskInput("   ", null, TaskPriority.LOW, false, null)
        )
        assertEquals(CreateTaskOutcome.InvalidTitle, outcome)
        assertTrue(vm.uiState.value.isEmpty)
    }

    @Test
    fun `toggleCompleted flips flag`() = runTest {
        val vm = newViewModel()
        val outcome = vm.createTask(
            CreateTaskInput("X", null, TaskPriority.LOW, false, null)
        ) as CreateTaskOutcome.Created
        vm.toggleCompleted(outcome.task)
        val task = vm.uiState.value.sections.flatMap { it.tasks }.single()
        assertEquals(true, task.isCompleted)
    }
}
