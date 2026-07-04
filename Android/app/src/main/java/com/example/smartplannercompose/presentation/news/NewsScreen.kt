package com.example.smartplannercompose.presentation.news

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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.smartplannercompose.data.news.FileImageCache
import com.example.smartplannercompose.data.news.ImageCache
import com.example.smartplannercompose.data.news.NewsArticle
import com.example.smartplannercompose.designsystem.Spacing
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
    viewModel: NewsViewModel
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val imageCache: ImageCache = remember(context) { FileImageCache.getInstance(context) }

    when (val s = state) {
        is NewsUiState.Loading -> Box(modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
        is NewsUiState.Empty -> NewsMessage(modifier, "Новостей пока нет", viewModel::retry)
        is NewsUiState.Error -> NewsMessage(modifier, s.message, viewModel::retry)
        is NewsUiState.Loaded -> LazyColumn(
            modifier = modifier.fillMaxSize(),
            contentPadding = PaddingValues(Spacing.lg),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            items(s.articles, key = { it.id }) { NewsCard(it, imageCache) }
        }
    }
}

@Composable
private fun NewsMessage(modifier: Modifier, message: String, onRetry: () -> Unit) {
    Column(
        modifier = modifier.fillMaxSize().padding(Spacing.xl),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = message, style = MaterialTheme.typography.bodyLarge)
        Spacer(modifier = Modifier.height(Spacing.md))
        Button(onClick = onRetry) { Text("Повторить") }
    }
}

@Composable
private fun NewsCard(article: NewsArticle, imageCache: ImageCache) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Spacing.md)) {
            NewsImage(
                imageUrl = article.imageUrl,
                imageCache = imageCache,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
                    .clip(RoundedCornerShape(12.dp))
            )
            Spacer(modifier = Modifier.height(Spacing.md))
            Text(article.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(Spacing.sm))
            Text(article.abstract.ifBlank { "Без описания" }, style = MaterialTheme.typography.bodyMedium)
            Spacer(modifier = Modifier.height(Spacing.sm))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(article.source, style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(formatNewsDate(article.publishedAtMillis), style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun NewsImage(imageUrl: String?, imageCache: ImageCache, modifier: Modifier = Modifier) {
    val imageState by produceState<NewsImageState>(
        initialValue = NewsImageState.Loading,
        key1 = imageUrl
    ) {
        if (imageUrl.isNullOrBlank()) {
            value = NewsImageState.NoImage
            return@produceState
        }
        value = NewsImageState.Loading
        val bitmap = imageCache.loadImage(imageUrl)
        value = if (bitmap == null) NewsImageState.Error else NewsImageState.Success(bitmap)
    }

    Box(
        modifier = modifier.background(Color(0xFFECECEC)),
        contentAlignment = Alignment.Center
    ) {
        when (val s = imageState) {
            is NewsImageState.Loading -> CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
            is NewsImageState.NoImage -> Icon(Icons.Default.Image, contentDescription = null, tint = Color.Gray)
            is NewsImageState.Error -> Icon(Icons.Default.BrokenImage, contentDescription = null, tint = Color.Gray)
            is NewsImageState.Success -> androidx.compose.foundation.Image(
                bitmap = s.bitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        }
    }
}

private fun formatNewsDate(millis: Long): String =
    SimpleDateFormat("dd MMM yyyy, HH:mm", Locale.getDefault()).format(Date(millis))
