package com.example.smartplannercompose.presentation.tasks

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.smartplannercompose.presentation.tasks.TestTags

/**
 * Test-only host that wires TasksListScreen and CreateTaskScreen together
 * with a single ViewModel — used by Compose UI tests so they don't depend
 * on the full activity scaffold.
 */
@Composable
fun TestHarnessTasksScreen(viewModel: TasksViewModel) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    var creating by remember { mutableStateOf(false) }

    Scaffold(
        floatingActionButton = {
            if (!creating) {
                FloatingActionButton(
                    onClick = { creating = true },
                    modifier = Modifier.testTag(TestTags.ADD_TASK_FAB)
                ) { Icon(Icons.Default.Edit, contentDescription = "Добавить задачу") }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize()) {
            if (creating) {
                CreateTaskScreen(
                    modifier = Modifier.fillMaxSize(),
                    onSave = { input ->
                        when (viewModel.createTask(input)) {
                            is CreateTaskOutcome.Created -> creating = false
                            else -> { /* keep open */ }
                        }
                    },
                    onCancel = { creating = false }
                )
            } else {
                TasksListScreen(
                    modifier = Modifier.fillMaxSize(),
                    sections = state.sections,
                    filter = state.filter,
                    isEmpty = state.isEmpty,
                    onFilterChange = viewModel::setFilter,
                    onToggleCompleted = viewModel::toggleCompleted,
                    onEmptyAddClick = { creating = true }
                )
            }
        }
    }
}
