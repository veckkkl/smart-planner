package com.example.smartplannercompose.presentation.dashboard

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.smartplannercompose.designsystem.DashboardPalette
import com.example.smartplannercompose.designsystem.SectionCard
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.dashboard.DashboardStatistics

@Composable
fun StatisticsCardsRow(stats: DashboardStatistics, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        StatCard(modifier = Modifier.weight(1f), title = "Всего", value = stats.total)
        StatCard(modifier = Modifier.weight(1f), title = "Готово", value = stats.completed, accent = DashboardPalette.completed)
        StatCard(modifier = Modifier.weight(1f), title = "Активны", value = stats.active, accent = DashboardPalette.active)
    }
}

@Composable
fun StatisticsSecondaryRow(stats: DashboardStatistics, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        StatCard(modifier = Modifier.weight(1f), title = "Просрочены", value = stats.overdue, accent = DashboardPalette.overdue)
        StatCard(modifier = Modifier.weight(1f), title = "Без даты", value = stats.withoutDate, accent = DashboardPalette.withoutDate)
    }
}

@Composable
private fun StatCard(modifier: Modifier = Modifier, title: String, value: Int, accent: Color? = null) {
    SectionCard(modifier = modifier) {
        Column {
            Text(
                text = value.toString(),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.SemiBold,
                color = accent ?: MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(Spacing.xs))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun StatisticsDonut(stats: DashboardStatistics, modifier: Modifier = Modifier) {
    SectionCard(modifier = modifier) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DonutChart(
                modifier = Modifier.size(120.dp),
                values = listOf(
                    stats.completed.toFloat() to DashboardPalette.completed,
                    stats.active.toFloat() to DashboardPalette.active,
                    stats.overdue.toFloat() to DashboardPalette.overdue,
                    stats.withoutDate.toFloat() to DashboardPalette.withoutDate
                )
            )
            Spacer(modifier = Modifier.width(Spacing.lg))
            Column {
                LegendRow(color = DashboardPalette.completed, label = "Готово", count = stats.completed)
                LegendRow(color = DashboardPalette.active, label = "Активны", count = stats.active)
                LegendRow(color = DashboardPalette.overdue, label = "Просрочены", count = stats.overdue)
                LegendRow(color = DashboardPalette.withoutDate, label = "Без даты", count = stats.withoutDate)
            }
        }
    }
}

@Composable
private fun DonutChart(modifier: Modifier = Modifier, values: List<Pair<Float, Color>>) {
    val total = values.sumOf { it.first.toDouble() }.toFloat().coerceAtLeast(0.0001f)
    Canvas(modifier = modifier) {
        val stroke = Stroke(width = 24f)
        var startAngle = -90f
        for ((value, color) in values) {
            val sweep = if (value <= 0f) 0f else (value / total) * 360f
            if (sweep > 0f) {
                drawArc(
                    color = color,
                    startAngle = startAngle,
                    sweepAngle = sweep,
                    useCenter = false,
                    size = Size(size.minDimension - stroke.width, size.minDimension - stroke.width),
                    topLeft = androidx.compose.ui.geometry.Offset(stroke.width / 2, stroke.width / 2),
                    style = stroke
                )
            }
            startAngle += sweep
        }
    }
}

@Composable
private fun LegendRow(color: Color, label: String, count: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Spacing.xs),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(color))
        Spacer(modifier = Modifier.width(Spacing.sm))
        Text(text = label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Text(text = count.toString(), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
    }
}
