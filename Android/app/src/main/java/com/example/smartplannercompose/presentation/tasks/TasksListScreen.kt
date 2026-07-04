package com.example.smartplannercompose.presentation.tasks

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.example.smartplannercompose.designsystem.PriorityPalette
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.tasks.Task
import com.example.smartplannercompose.domain.tasks.TaskFilter
import com.example.smartplannercompose.domain.tasks.TaskListSection
import com.example.smartplannercompose.domain.tasks.TaskSectionResult

@Composable
fun TasksListScreen(
    modifier: Modifier = Modifier,
    sections: List<TaskSectionResult>,
    filter: TaskFilter,
    isEmpty: Boolean,
    onFilterChange: (TaskFilter) -> Unit,
    onToggleCompleted: (Task) -> Unit,
    onEmptyAddClick: () -> Unit
) {
    Column(modifier = modifier.fillMaxSize()) {
        FilterRow(filter = filter, onFilterChange = onFilterChange)
        Box(modifier = Modifier.fillMaxSize()) {
            if (isEmpty || sections.all { it.tasks.isEmpty() }) {
                EmptyTasksState(modifier = Modifier.fillMaxSize(), onAddClick = onEmptyAddClick)
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .testTag(TestTags.TASKS_LIST),
                    contentPadding = PaddingValues(vertical = Spacing.sm)
                ) {
                    for (section in sections) {
                        if (section.section != TaskListSection.FLAT) {
                            item(key = "header-${section.section.name}") {
                                SectionHeader(title = section.section.title)
                            }
                        }
                        items(section.tasks, key = { it.id }) { task ->
                            TaskItem(task = task, onToggleCompleted = { onToggleCompleted(task) })
                        }
                    }
                }
            }
        }
    }
}

object TestTags {
    const val TASKS_LIST = "tasks_list"
    const val ADD_TASK_FAB = "add_task_fab"
    const val TASK_TITLE_FIELD = "task_title_field"
    const val SAVE_TASK_BUTTON = "save_task_button"
}

@Composable
private fun FilterRow(filter: TaskFilter, onFilterChange: (TaskFilter) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        TaskFilter.values().forEach { value ->
            FilterChip(
                selected = filter == value,
                onClick = { onFilterChange(value) },
                label = { Text(value.title) }
            )
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        modifier = Modifier.padding(horizontal = Spacing.lg, vertical = Spacing.sm),
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

@Composable
private fun EmptyTasksState(modifier: Modifier, onAddClick: () -> Unit) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(Spacing.sm))
        Text(text = "Нет задач", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(Spacing.xs))
        Text(
            text = "Добавьте первую задачу, нажав +",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun TaskItem(task: Task, onToggleCompleted: () -> Unit) {
    val alpha = if (task.isCompleted) 0.4f else 1f
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(6.dp)
                .height(40.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(PriorityPalette.colorFor(task.priority))
        )
        Spacer(modifier = Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f).alpha(alpha)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = task.title, style = MaterialTheme.typography.titleMedium)
                if (task.isFlagged) {
                    Spacer(modifier = Modifier.width(Spacing.xs))
                    Text(text = "🚩")
                }
            }
            val subtitle = buildList {
                if (!task.details.isNullOrBlank()) add(task.details)
                formatDeadline(task.deadlineMillis)?.let { add(it) }
            }
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle.joinToString(" • "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        IconButton(onClick = onToggleCompleted) {
            Icon(
                imageVector = if (task.isCompleted) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                contentDescription = "Выполнено"
            )
        }
    }
}
