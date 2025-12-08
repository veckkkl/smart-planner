package com.example.smartplannercompose

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import java.util.Calendar
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip



@Composable
fun TasksScreen(
    modifier: Modifier = Modifier,
    tasks: List<Task>,
    onToggleCompleted: (Task) -> Unit,
    onEmptyAddClick: () -> Unit
) {
    Box(modifier = modifier.fillMaxSize()) {
        if (tasks.isEmpty()) {
            EmptyTasksState(
                modifier = Modifier.fillMaxSize(),
                onAddClick = onEmptyAddClick
            )
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(tasks) { task ->
                    TaskItem(
                        task = task,
                        onToggleCompleted = { onToggleCompleted(task) }
                    )
                }
            }
        }
    }
}

@Composable
private fun EmptyTasksState(
    modifier: Modifier = Modifier,
    onAddClick: () -> Unit
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            tint = Color.LightGray,
            modifier = Modifier.size(48.dp)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Нет задач",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Добавьте первую задачу, нажав +",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
        )
    }
}

@Composable
private fun TaskItem(
    task: Task,
    onToggleCompleted: () -> Unit
) {
    val alpha = if (task.isCompleted) 0.4f else 1f

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(8.dp)
                .height(40.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(
                    when (task.priority) {
                        TaskPriority.LOW -> Color(0xFF4CAF50)    // зелёный
                        TaskPriority.MEDIUM -> Color(0xFFFFC107) // оранжевый
                        TaskPriority.HIGH -> Color(0xFFF44336)   // красный
                    }
                )
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(
            modifier = Modifier
                .weight(1f)
                .alpha(alpha)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = task.title,
                    style = MaterialTheme.typography.titleMedium,
                )
                if (task.isFlagged) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(text = "🚩")
                }
            }

            val subtitleParts = buildList {
                if (!task.description.isNullOrBlank()) add(task.description)
                val deadline = formatDeadline(task.deadlineMillis)
                if (deadline != null) add(deadline)
            }

            if (subtitleParts.isNotEmpty()) {
                Text(
                    text = subtitleParts.joinToString(" • "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                )
            }
        }

        IconButton(onClick = onToggleCompleted) {
            Icon(
                imageVector = if (task.isCompleted) {
                    Icons.Default.CheckCircle
                } else {
                    Icons.Default.RadioButtonUnchecked
                },
                contentDescription = "Выполнено"
            )
        }
    }
}

@Composable
fun CreateTaskScreen(
    modifier: Modifier = Modifier,
    onSave: (Task) -> Unit,
    onCancel: () -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var priority by remember { mutableStateOf(TaskPriority.MEDIUM) }
    var isFlagged by remember { mutableStateOf(false) }

    var useDeadline by remember { mutableStateOf(false) }
    var deadlineMillis by remember { mutableStateOf<Long?>(null) }

    val context = LocalContext.current
    val calendar = Calendar.getInstance()

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("Название задачи *") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )

        OutlinedTextField(
            value = description,
            onValueChange = { description = it },
            label = { Text("Описание") },
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 80.dp)
        )

        Text("Приоритет")
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TaskPriority.values().forEach { p ->
                FilterChip(
                    selected = priority == p,
                    onClick = { priority = p },
                    label = { Text(p.title) }
                )
            }
        }

        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Флаг")
            Switch(
                checked = isFlagged,
                onCheckedChange = { isFlagged = it }
            )
        }

        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Выбрать дату завершения")
            Switch(
                checked = useDeadline,
                onCheckedChange = { checked ->
                    useDeadline = checked
                    if (!checked) deadlineMillis = null
                }
            )
        }

        if (useDeadline) {
            val deadlineText = formatDeadline(deadlineMillis) ?: "Выбрать дату и время"

            Button(
                onClick = {
                    val dateDialog = DatePickerDialog(
                        context,
                        { _, year, month, dayOfMonth ->
                            calendar.set(Calendar.YEAR, year)
                            calendar.set(Calendar.MONTH, month)
                            calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth)

                            val timeDialog = TimePickerDialog(
                                context,
                                { _, hourOfDay, minute ->
                                    calendar.set(Calendar.HOUR_OF_DAY, hourOfDay)
                                    calendar.set(Calendar.MINUTE, minute)
                                    deadlineMillis = calendar.timeInMillis
                                },
                                calendar.get(Calendar.HOUR_OF_DAY),
                                calendar.get(Calendar.MINUTE),
                                true
                            )
                            timeDialog.show()
                        },
                        calendar.get(Calendar.YEAR),
                        calendar.get(Calendar.MONTH),
                        calendar.get(Calendar.DAY_OF_MONTH)
                    )
                    dateDialog.show()
                }
            ) {
                Text(deadlineText, textAlign = TextAlign.Start)
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) {
                Text("Отменить")
            }
            Button(
                onClick = {
                    if (title.isNotBlank()) {
                        onSave(
                            Task(
                                title = title,
                                description = description.ifBlank { null },
                                priority = priority,
                                isFlagged = isFlagged,
                                deadlineMillis = deadlineMillis
                            )
                        )
                    }
                },
                modifier = Modifier.weight(1f),
                enabled = title.isNotBlank()
            ) {
                Text("Сохранить")
            }
        }
    }
}

