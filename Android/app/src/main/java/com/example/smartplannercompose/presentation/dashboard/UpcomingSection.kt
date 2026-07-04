package com.example.smartplannercompose.presentation.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import com.example.smartplannercompose.designsystem.SectionCard
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.tasks.Task
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun UpcomingSection(
    modifier: Modifier = Modifier,
    tasks: List<Task>
) {
    SectionCard(modifier = modifier) {
        Column {
            Text(text = "Ближайшие", style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(Spacing.sm))
            if (tasks.isEmpty()) {
                Text(
                    text = "Нет запланированных задач",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                for (task in tasks) {
                    UpcomingTaskRow(task)
                }
            }
        }
    }
}

@Composable
private fun UpcomingTaskRow(task: Task) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Spacing.xs),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = task.title,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        val deadline = task.deadlineMillis?.let {
            SimpleDateFormat("dd.MM HH:mm", Locale.getDefault()).format(Date(it))
        }
        if (deadline != null) {
            Text(
                text = deadline,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
