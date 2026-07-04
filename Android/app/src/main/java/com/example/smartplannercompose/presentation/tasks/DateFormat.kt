package com.example.smartplannercompose.presentation.tasks

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

internal fun formatDeadline(deadlineMillis: Long?): String? {
    if (deadlineMillis == null) return null
    val formatter = SimpleDateFormat("dd.MM HH:mm", Locale.getDefault())
    return formatter.format(Date(deadlineMillis))
}
