package com.example.smartplannercompose

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SmartPlannerApp() {
    var selectedTab by remember { mutableStateOf(BottomTab.TASKS) }

    var tasks by remember { mutableStateOf(listOf<Task>()) }
    var sortOption by remember { mutableStateOf(SortOption.NONE) }

    var isCreatingTask by remember { mutableStateOf(false) }

    val sortedTasks = remember(tasks, sortOption) {
        sortTasks(tasks, sortOption)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (selectedTab) {
                            BottomTab.HOME -> "Главная"
                            BottomTab.TASKS -> if (isCreatingTask) "Новая задача" else "Задачи"
                            BottomTab.NOTES -> "Записи"
                        }
                    )
                },
                actions = {
                    if (selectedTab == BottomTab.TASKS && isCreatingTask == false) {
                        SortMenu(
                            sortOption = sortOption,
                            onSortChange = { sortOption = it }
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            if (selectedTab == BottomTab.TASKS && isCreatingTask == false) {
                FloatingActionButton(onClick = { isCreatingTask = true }) {
                    Icon(Icons.Default.Edit, contentDescription = "Добавить задачу")
                }
            }
        },
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = selectedTab == BottomTab.HOME,
                    onClick = { selectedTab = BottomTab.HOME },
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("Главная") }
                )
                NavigationBarItem(
                    selected = selectedTab == BottomTab.TASKS,
                    onClick = {
                        selectedTab = BottomTab.TASKS
                        isCreatingTask = false
                    },
                    icon = { Icon(Icons.Default.List, contentDescription = null) },
                    label = { Text("Задачи") }
                )
                NavigationBarItem(
                    selected = selectedTab == BottomTab.NOTES,
                    onClick = { selectedTab = BottomTab.NOTES },
                    icon = { Icon(Icons.Default.Edit, contentDescription = null) },
                    label = { Text("Записи") }
                )
            }
        }
    ) { innerPadding ->
        when (selectedTab) {
            BottomTab.HOME -> HomeScreen(modifier = Modifier.padding(innerPadding))
            BottomTab.TASKS -> {
                if (isCreatingTask) {
                    CreateTaskScreen(
                        modifier = Modifier.padding(innerPadding),
                        onSave = { newTask ->
                            tasks = tasks + newTask
                            isCreatingTask = false
                        },
                        onCancel = { isCreatingTask = false }
                    )
                } else {
                    TasksScreen(
                        modifier = Modifier.padding(innerPadding),
                        tasks = sortedTasks,
                        onToggleCompleted = { task ->
                            tasks = tasks.map {
                                if (it.id == task.id) it.copy(isCompleted = !it.isCompleted) else it
                            }
                        },
                        onEmptyAddClick = { isCreatingTask = true }
                    )
                }
            }
            BottomTab.NOTES -> NotesScreen(modifier = Modifier.padding(innerPadding))
        }
    }
}

private fun sortTasks(tasks: List<Task>, sortOption: SortOption): List<Task> {
    val result = tasks.toMutableList()

    when (sortOption) {
        SortOption.NONE -> return result
        SortOption.DATE_NEWEST ->
            result.sortByDescending { it.createdAtMillis }
        SortOption.DATE_OLDEST ->
            result.sortBy { it.createdAtMillis }
        SortOption.PRIORITY_HIGH_FIRST ->
            result.sortByDescending { it.priority }
        SortOption.PRIORITY_LOW_FIRST ->
            result.sortBy { it.priority }
    }
    return result
}

@Composable
private fun SortMenu(
    sortOption: SortOption,
    onSortChange: (SortOption) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    IconButton(onClick = { expanded = true }) {
        Icon(Icons.Default.List, contentDescription = "Сортировка")
    }

    DropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        DropdownMenuItem(
            text = { Text("Новые сначала") },
            onClick = {
                onSortChange(SortOption.DATE_NEWEST)
                expanded = false
            }
        )
        DropdownMenuItem(
            text = { Text("Старые сначала") },
            onClick = {
                onSortChange(SortOption.DATE_OLDEST)
                expanded = false
            }
        )
        DropdownMenuItem(
            text = { Text("Сначала сложные") },
            onClick = {
                onSortChange(SortOption.PRIORITY_HIGH_FIRST)
                expanded = false
            }
        )
        DropdownMenuItem(
            text = { Text("Сначала лёгкие") },
            onClick = {
                onSortChange(SortOption.PRIORITY_LOW_FIRST)
                expanded = false
            }
        )
    }
}
