package com.example.smartplannercompose.app

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Article
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.smartplannercompose.domain.tasks.TaskSortOption
import com.example.smartplannercompose.presentation.dashboard.DashboardScreen
import com.example.smartplannercompose.presentation.dashboard.DashboardViewModel
import com.example.smartplannercompose.presentation.news.NewsScreen
import com.example.smartplannercompose.presentation.news.NewsViewModel
import com.example.smartplannercompose.presentation.tasks.CreateTaskScreen
import com.example.smartplannercompose.presentation.tasks.DayTasksScreen
import com.example.smartplannercompose.presentation.tasks.TasksListScreen
import com.example.smartplannercompose.presentation.tasks.TasksViewModel
import com.example.smartplannercompose.presentation.tasks.CreateTaskOutcome
import com.example.smartplannercompose.presentation.tasks.TestTags

enum class BottomTab { NEWS, HOME, TASKS, NOTES }

private sealed interface TaskRoute {
    data object List : TaskRoute
    data object Create : TaskRoute
    data class Day(val dayMillis: Long) : TaskRoute
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SmartPlannerApp(container: AppContainer) {
    val tasksVm = remember {
        TasksViewModel(
            repository = container.taskRepository,
            processor = container.taskListProcessor,
            createTaskUseCase = container.createTaskUseCase
        )
    }
    val dashboardVm = remember {
        DashboardViewModel(
            repository = container.taskRepository,
            service = container.dashboardService
        )
    }
    val newsVm = remember {
        NewsViewModel(repository = container.newsRepository, cache = container.newsCache)
    }

    var tab by rememberSaveable { mutableStateOf(BottomTab.HOME) }
    var taskRoute by remember { mutableStateOf<TaskRoute>(TaskRoute.List) }
    var sortMenuOpen by remember { mutableStateOf(false) }
    val tasksState by tasksVm.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = topBarTitle(tab, taskRoute)) },
                navigationIcon = {
                    val showBack = tab == BottomTab.TASKS && taskRoute != TaskRoute.List ||
                        tab == BottomTab.HOME && taskRoute is TaskRoute.Day
                    if (showBack) {
                        IconButton(onClick = { taskRoute = TaskRoute.List }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Назад")
                        }
                    }
                },
                actions = {
                    if (tab == BottomTab.TASKS && taskRoute == TaskRoute.List) {
                        IconButton(onClick = { sortMenuOpen = true }) {
                            Icon(Icons.AutoMirrored.Filled.Sort, contentDescription = "Сортировка")
                        }
                        DropdownMenu(expanded = sortMenuOpen, onDismissRequest = { sortMenuOpen = false }) {
                            TaskSortOption.values().forEach { option ->
                                DropdownMenuItem(
                                    text = { Text(option.title) },
                                    onClick = {
                                        tasksVm.setSort(option)
                                        sortMenuOpen = false
                                    }
                                )
                            }
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            if (tab == BottomTab.TASKS && taskRoute == TaskRoute.List) {
                FloatingActionButton(
                    onClick = { taskRoute = TaskRoute.Create },
                    modifier = Modifier.testTag(TestTags.ADD_TASK_FAB)
                ) {
                    Icon(Icons.Default.Edit, contentDescription = "Добавить задачу")
                }
            }
        },
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = tab == BottomTab.NEWS,
                    onClick = { tab = BottomTab.NEWS },
                    icon = { Icon(Icons.AutoMirrored.Filled.Article, contentDescription = null) },
                    label = { Text("Новости") }
                )
                NavigationBarItem(
                    selected = tab == BottomTab.HOME,
                    onClick = { tab = BottomTab.HOME; taskRoute = TaskRoute.List },
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("Главная") }
                )
                NavigationBarItem(
                    selected = tab == BottomTab.TASKS,
                    onClick = { tab = BottomTab.TASKS; taskRoute = TaskRoute.List },
                    icon = { Icon(Icons.AutoMirrored.Filled.List, contentDescription = null) },
                    label = { Text("Задачи") }
                )
                NavigationBarItem(
                    selected = tab == BottomTab.NOTES,
                    onClick = { tab = BottomTab.NOTES },
                    icon = { Icon(Icons.Default.Edit, contentDescription = null) },
                    label = { Text("Записи") }
                )
            }
        }
    ) { innerPadding ->
        val contentModifier = Modifier.padding(innerPadding)
        when (tab) {
            BottomTab.NEWS -> NewsScreen(modifier = contentModifier, viewModel = newsVm)
            BottomTab.HOME -> {
                when (val route = taskRoute) {
                    is TaskRoute.Day -> DayTasksScreen(
                        modifier = contentModifier,
                        dayMillis = route.dayMillis,
                        tasks = dashboardVm.tasksOn(route.dayMillis),
                        onToggleCompleted = { dashboardVm.toggleCompletion(it.id) }
                    )
                    else -> DashboardScreen(
                        modifier = contentModifier,
                        viewModel = dashboardVm,
                        onDaySelected = { taskRoute = TaskRoute.Day(it) }
                    )
                }
            }
            BottomTab.TASKS -> when (taskRoute) {
                TaskRoute.Create -> CreateTaskScreen(
                    modifier = contentModifier,
                    onSave = { input ->
                        when (val outcome = tasksVm.createTask(input)) {
                            is CreateTaskOutcome.Created -> taskRoute = TaskRoute.List
                            CreateTaskOutcome.InvalidTitle -> { /* inline button is already disabled when blank */ }
                        }
                    },
                    onCancel = { taskRoute = TaskRoute.List }
                )
                else -> TasksListScreen(
                    modifier = contentModifier,
                    sections = tasksState.sections,
                    filter = tasksState.filter,
                    isEmpty = tasksState.isEmpty,
                    onFilterChange = tasksVm::setFilter,
                    onToggleCompleted = tasksVm::toggleCompleted,
                    onEmptyAddClick = { taskRoute = TaskRoute.Create }
                )
            }
            BottomTab.NOTES -> com.example.smartplannercompose.presentation.NotesPlaceholderScreen(modifier = contentModifier)
        }
    }
}

private fun topBarTitle(tab: BottomTab, route: TaskRoute): String = when (tab) {
    BottomTab.NEWS -> "Новости"
    BottomTab.HOME -> if (route is TaskRoute.Day) "Задачи на день" else "Главная"
    BottomTab.TASKS -> when (route) {
        TaskRoute.Create -> "Новая задача"
        is TaskRoute.Day -> "Задачи на день"
        TaskRoute.List -> "Задачи"
    }
    BottomTab.NOTES -> "Записи"
}
