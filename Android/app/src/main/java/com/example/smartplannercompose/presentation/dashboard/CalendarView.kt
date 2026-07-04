package com.example.smartplannercompose.presentation.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.smartplannercompose.designsystem.DashboardPalette
import com.example.smartplannercompose.designsystem.SectionCard
import com.example.smartplannercompose.designsystem.Spacing
import com.example.smartplannercompose.domain.dashboard.DayMarker
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Composable
fun TasksCalendar(
    modifier: Modifier = Modifier,
    nowMillis: Long,
    markerFor: (Long) -> DayMarker?,
    onDaySelected: (Long) -> Unit
) {
    var anchor by remember { mutableStateOf(monthStart(nowMillis)) }
    val title = remember(anchor) {
        SimpleDateFormat("LLLL yyyy", Locale.getDefault()).format(Date(anchor))
            .replaceFirstChar { it.uppercaseChar() }
    }

    SectionCard(modifier = modifier) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { anchor = shiftMonth(anchor, -1) }) {
                    Icon(Icons.Default.ChevronLeft, contentDescription = "Предыдущий месяц")
                }
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
                IconButton(onClick = { anchor = shiftMonth(anchor, 1) }) {
                    Icon(Icons.Default.ChevronRight, contentDescription = "Следующий месяц")
                }
            }
            WeekHeader()
            MonthGrid(
                anchor = anchor,
                nowMillis = nowMillis,
                markerFor = markerFor,
                onDaySelected = onDaySelected
            )
        }
    }
}

@Composable
private fun WeekHeader() {
    val names = listOf("Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс")
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.xs)) {
        for (n in names) {
            Text(
                text = n,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

@Composable
private fun MonthGrid(
    anchor: Long,
    nowMillis: Long,
    markerFor: (Long) -> DayMarker?,
    onDaySelected: (Long) -> Unit
) {
    val cal = Calendar.getInstance().apply { timeInMillis = anchor }
    val daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)
    val firstDow = ((cal.get(Calendar.DAY_OF_WEEK) + 5) % 7) // Mon=0..Sun=6
    val cells = firstDow + daysInMonth
    val rows = (cells + 6) / 7

    Column {
        for (row in 0 until rows) {
            Row(modifier = Modifier.fillMaxWidth()) {
                for (col in 0 until 7) {
                    val cellIndex = row * 7 + col
                    val dayNum = cellIndex - firstDow + 1
                    if (dayNum in 1..daysInMonth) {
                        val dayCal = (cal.clone() as Calendar).apply {
                            set(Calendar.DAY_OF_MONTH, dayNum)
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        DayCell(
                            modifier = Modifier.weight(1f),
                            day = dayNum,
                            isToday = isSameDay(dayCal.timeInMillis, nowMillis),
                            marker = markerFor(dayCal.timeInMillis),
                            onClick = { onDaySelected(dayCal.timeInMillis) }
                        )
                    } else {
                        Box(modifier = Modifier.weight(1f).aspectRatio(1f))
                    }
                }
            }
        }
    }
}

@Composable
private fun DayCell(
    modifier: Modifier,
    day: Int,
    isToday: Boolean,
    marker: DayMarker?,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(CircleShape)
            .let { if (isToday) it.border(1.dp, MaterialTheme.colorScheme.primary, CircleShape) else it }
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = day.toString(), style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isToday) FontWeight.Bold else FontWeight.Normal)
            if (marker != null) {
                Row(modifier = Modifier.padding(top = 2.dp)) {
                    if (marker.hasOverdue) Dot(DashboardPalette.overdue)
                    if (marker.hasActive) Dot(DashboardPalette.active)
                    if (marker.hasCompleted) Dot(DashboardPalette.completed)
                }
            }
        }
    }
}

@Composable
private fun Dot(color: Color) {
    Box(
        modifier = Modifier
            .size(4.dp)
            .padding(horizontal = 1.dp)
            .clip(CircleShape)
            .background(color)
    )
}

private fun monthStart(millis: Long): Long {
    val c = Calendar.getInstance().apply { timeInMillis = millis }
    c.set(Calendar.DAY_OF_MONTH, 1)
    c.set(Calendar.HOUR_OF_DAY, 0); c.set(Calendar.MINUTE, 0)
    c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0)
    return c.timeInMillis
}

private fun shiftMonth(millis: Long, delta: Int): Long {
    val c = Calendar.getInstance().apply { timeInMillis = millis }
    c.add(Calendar.MONTH, delta)
    return c.timeInMillis
}

private fun isSameDay(a: Long, b: Long): Boolean {
    val ca = Calendar.getInstance().apply { timeInMillis = a }
    val cb = Calendar.getInstance().apply { timeInMillis = b }
    return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) &&
        ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
}
