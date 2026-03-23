package ch.freaxnx01.quicktask.vikunja.ui.history

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ch.freaxnx01.quicktask.vikunja.data.TaskHistoryEntry

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecentTasksScreen(
    viewModel: RecentTasksViewModel = hiltViewModel(),
    onSettingsClick: () -> Unit = {},
) {
    val entries by viewModel.entries.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("QuickTask") },
                actions = {
                    IconButton(onClick = onSettingsClick) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                },
            )
        },
    ) { padding ->
        if (entries.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "No tasks yet.\nShare a URL or text from another app to get started.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(32.dp),
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(entries) { entry ->
                    TaskHistoryItem(entry)
                }
            }
        }
    }
}

@Composable
private fun TaskHistoryItem(entry: TaskHistoryEntry) {
    Column {
        Text(
            text = entry.taskName,
            style = MaterialTheme.typography.bodyLarge,
        )
        Text(
            text = "${entry.projectName} • ${formatRelativeTime(entry.timestamp)}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun formatRelativeTime(timestamp: Long): String {
    val diff = System.currentTimeMillis() - timestamp
    val minutes = diff / 60_000
    val hours = minutes / 60
    val days = hours / 24

    return when {
        minutes < 1 -> "just now"
        minutes < 60 -> "${minutes}m ago"
        hours < 24 -> "${hours}h ago"
        days < 30 -> "${days}d ago"
        else -> "${days / 30}mo ago"
    }
}
