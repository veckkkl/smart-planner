package com.example.smartplannercompose.presentation.tasks

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import com.example.smartplannercompose.designsystem.EmptyState
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.tasks.Task
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun DayTasksScreen(
    modifier: Modifier = Modifier,
    dayMillis: Long,
    tasks: List<Task>,
    onToggleCompleted: (Task) -> Unit
) {
    val title = remember(dayMillis) {
        SimpleDateFormat("d MMMM yyyy", Locale.getDefault()).format(Date(dayMillis))
    }
    Column(modifier = modifier.fillMaxSize()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(Spacing.lg)
        )
        if (tasks.isEmpty()) {
            EmptyState(title = "Нет задач на этот день")
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = Spacing.sm)
            ) {
                items(tasks, key = { it.id }) { task ->
                    TaskItem(task = task, onToggleCompleted = { onToggleCompleted(task) })
                }
            }
        }
    }
}
