package com.example.smartplannercompose.presentation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.example.smartplannercompose.designsystem.EmptyState

@Composable
fun NotesPlaceholderScreen(modifier: Modifier = Modifier) {
    EmptyState(
        modifier = modifier,
        title = "Записи",
        subtitle = "Раздел появится позже"
    )
}
