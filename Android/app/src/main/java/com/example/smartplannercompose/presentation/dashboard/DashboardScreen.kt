package com.example.smartplannercompose.presentation.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.smartplannercompose.core.Clock
import com.example.smartplannercompose.core.SystemClock
import com.example.smartplannercompose.designsystem.EmptyState
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.dashboard.DashboardPeriod

@Composable
fun DashboardScreen(
    modifier: Modifier = Modifier,
    viewModel: DashboardViewModel,
    onDaySelected: (Long) -> Unit,
    clock: Clock = SystemClock
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val now = remember { clock.nowMillis() }

    if (!state.hasAnyTasks) {
        EmptyState(
            modifier = modifier,
            title = "Нет задач",
            subtitle = "Создайте первую задачу, чтобы увидеть статистику"
        )
        return
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Spacing.lg),
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Text(text = "Главная", style = MaterialTheme.typography.headlineSmall)
        PeriodSelector(period = state.period, onChange = viewModel::setPeriod)
        StatisticsCardsRow(stats = state.statistics)
        StatisticsSecondaryRow(stats = state.statistics)
        StatisticsDonut(stats = state.statistics)
        TasksCalendar(
            nowMillis = now,
            markerFor = { dayMillis -> viewModel.marker(dayMillis) },
            onDaySelected = onDaySelected
        )
        UpcomingSection(tasks = state.upcoming)
    }
}

@Composable
private fun PeriodSelector(period: DashboardPeriod, onChange: (DashboardPeriod) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        DashboardPeriod.values().forEach { value ->
            FilterChip(
                selected = period == value,
                onClick = { onChange(value) },
                label = { Text(value.title) }
            )
        }
    }
}
