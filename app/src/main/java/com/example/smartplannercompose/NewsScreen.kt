package com.example.smartplannercompose

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrokenImage
import androidx.compose.material.icons.filled.Image
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private sealed interface NewsImageState {
    data object Loading : NewsImageState
    data object NoImage : NewsImageState
    data object Error : NewsImageState
    data class Success(val bitmap: android.graphics.Bitmap) : NewsImageState
}

@Composable
fun NewsScreen(
    modifier: Modifier = Modifier,
    viewModel: NewsViewModel = viewModel()
) {
    val state by viewModel.uiState.collectAsState()
    val imageLoader = rememberImageLoader()

    when (val uiState = state) {
        is NewsUiState.Loading -> {
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }

        is NewsUiState.Empty -> {
            NewsMessageState(
                modifier = modifier,
                message = "Новостей пока нет",
                showRetry = true,
                onRetry = viewModel::retry
            )
        }

        is NewsUiState.Error -> {
            NewsMessageState(
                modifier = modifier,
                message = uiState.message,
                showRetry = true,
                onRetry = viewModel::retry
            )
        }

        is NewsUiState.Loaded -> {
            LazyColumn(
                modifier = modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(
                    items = uiState.articles,
                    key = { it.id }
                ) { article ->
                    NewsCard(
                        article = article,
                        imageLoader = imageLoader
                    )
                }
            }
        }
    }
}

@Composable
private fun NewsMessageState(
    modifier: Modifier,
    message: String,
    showRetry: Boolean,
    onRetry: () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.8f)
        )

        if (showRetry) {
            Spacer(modifier = Modifier.height(12.dp))
            Button(onClick = onRetry) {
                Text("Повторить")
            }
        }
    }
}

@Composable
private fun NewsCard(
    article: NewsArticle,
    imageLoader: ImageLoader
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            NewsImage(
                imageUrl = article.imageUrl,
                imageLoader = imageLoader,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
                    .clip(RoundedCornerShape(12.dp))
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = article.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = article.abstract.ifBlank { "Без описания" },
                style = MaterialTheme.typography.bodyMedium
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = article.source,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = formatNewsDate(article.publishedAtMillis),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun NewsImage(
    imageUrl: String?,
    imageLoader: ImageLoader,
    modifier: Modifier = Modifier
) {
    val imageState by produceState<NewsImageState>(
        initialValue = NewsImageState.Loading,
        key1 = imageUrl,
        key2 = imageLoader
    ) {
        if (imageUrl.isNullOrBlank()) {
            value = NewsImageState.NoImage
            return@produceState
        }

        value = NewsImageState.Loading

        val bitmap = imageLoader.loadImage(imageUrl)
        value = if (bitmap == null) {
            NewsImageState.Error
        } else {
            NewsImageState.Success(bitmap)
        }
    }

    Box(
        modifier = modifier.background(Color(0xFFECECEC)),
        contentAlignment = Alignment.Center
    ) {
        when (val state = imageState) {
            is NewsImageState.Loading -> CircularProgressIndicator(modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
            is NewsImageState.NoImage -> Icon(Icons.Default.Image, contentDescription = null, tint = Color.Gray)
            is NewsImageState.Error -> Icon(Icons.Default.BrokenImage, contentDescription = null, tint = Color.Gray)
            is NewsImageState.Success -> androidx.compose.foundation.Image(
                bitmap = state.bitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        }
    }
}

private fun formatNewsDate(millis: Long): String {
    val formatter = SimpleDateFormat("dd MMM yyyy, HH:mm", Locale.getDefault())
    return formatter.format(Date(millis))
}
