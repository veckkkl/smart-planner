package com.example.smartplannercompose.presentation.tasks

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.tasks.CreateTaskInput
import com.example.smartplannercompose.domain.tasks.TaskPriority
import java.util.Calendar

@Composable
fun CreateTaskScreen(
    modifier: Modifier = Modifier,
    onSave: (CreateTaskInput) -> Unit,
    onCancel: () -> Unit
) {
    var title by remember { mutableStateOf("") }
    var details by remember { mutableStateOf("") }
    var priority by remember { mutableStateOf(TaskPriority.MEDIUM) }
    var isFlagged by remember { mutableStateOf(false) }
    var useDeadline by remember { mutableStateOf(false) }
    var deadlineMillis by remember { mutableStateOf<Long?>(null) }

    val context = LocalContext.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(Spacing.lg),
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("Название задачи *") },
            singleLine = true,
            modifier = Modifier
                .fillMaxWidth()
                .testTag(TestTags.TASK_TITLE_FIELD)
        )

        OutlinedTextField(
            value = details,
            onValueChange = { details = it },
            label = { Text("Описание") },
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 80.dp)
        )

        Text("Приоритет")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            TaskPriority.values().forEach { value ->
                FilterChip(
                    selected = priority == value,
                    onClick = { priority = value },
                    label = { Text(value.title) }
                )
            }
        }

        SwitchRow(label = "Флаг", checked = isFlagged, onCheckedChange = { isFlagged = it })
        SwitchRow(
            label = "Выбрать дату завершения",
            checked = useDeadline,
            onCheckedChange = { checked ->
                useDeadline = checked
                if (!checked) deadlineMillis = null
            }
        )

        if (useDeadline) {
            val deadlineText = formatDeadline(deadlineMillis) ?: "Выбрать дату и время"
            Button(
                onClick = {
                    pickDeadline(context) { picked -> deadlineMillis = picked }
                }
            ) { Text(deadlineText) }
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
        ) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.weight(1f)
            ) { Text("Отменить") }
            Button(
                onClick = {
                    onSave(
                        CreateTaskInput(
                            title = title,
                            details = details.ifBlank { null },
                            priority = priority,
                            isFlagged = isFlagged,
                            deadlineMillis = deadlineMillis
                        )
                    )
                },
                modifier = Modifier
                    .weight(1f)
                    .testTag(TestTags.SAVE_TASK_BUTTON),
                enabled = title.isNotBlank()
            ) { Text("Сохранить") }
        }
    }
}

@Composable
private fun SwitchRow(label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label)
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

private fun pickDeadline(context: android.content.Context, onPicked: (Long) -> Unit) {
    val calendar = Calendar.getInstance()
    DatePickerDialog(
        context,
        { _, year, month, dayOfMonth ->
            calendar.set(Calendar.YEAR, year)
            calendar.set(Calendar.MONTH, month)
            calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth)
            TimePickerDialog(
                context,
                { _, hourOfDay, minute ->
                    calendar.set(Calendar.HOUR_OF_DAY, hourOfDay)
                    calendar.set(Calendar.MINUTE, minute)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    onPicked(calendar.timeInMillis)
                },
                calendar.get(Calendar.HOUR_OF_DAY),
                calendar.get(Calendar.MINUTE),
                true
            ).show()
        },
        calendar.get(Calendar.YEAR),
        calendar.get(Calendar.MONTH),
        calendar.get(Calendar.DAY_OF_MONTH)
    ).show()
}
