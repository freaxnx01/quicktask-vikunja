package ch.freaxnx01.quicktask.vikunja.ui.share

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ch.freaxnx01.quicktask.vikunja.model.Project

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProjectPickerScreen(
    viewModel: ShareViewModel = hiltViewModel(),
    onDone: (projectName: String) -> Unit = {},
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(state.isDone) {
        if (state.isDone && state.addedToProject != null) {
            onDone(state.addedToProject!!)
        }
    }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Add to project") })
        },
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Task name preview
            if (state.taskName.isNotBlank()) {
                Text(
                    text = state.taskName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    maxLines = 2,
                )
            }

            // Search field
            OutlinedTextField(
                value = state.searchQuery,
                onValueChange = viewModel::onSearchQueryChanged,
                placeholder = { Text("Search projects...") },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .focusRequester(focusRequester),
            )

            when {
                state.isLoading && state.projects.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        CircularProgressIndicator()
                    }
                }
                state.error != null && state.projects.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = state.error!!,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier.padding(16.dp),
                        )
                    }
                }
                else -> {
                    val recentIds = remember { viewModel.getRecentProjectIds() }
                    val recentProjects = state.projects.filter { it.id in recentIds }
                    val otherProjects = state.projects.filter { it.id !in recentIds }

                    // Loading overlay when creating task
                    Box {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                        ) {
                            if (recentProjects.isNotEmpty()) {
                                item {
                                    SectionHeader("Recent")
                                }
                                items(recentProjects, key = { it.id }) { project ->
                                    ProjectItem(
                                        project = project,
                                        onClick = { viewModel.onProjectSelected(project) },
                                    )
                                }
                            }

                            if (otherProjects.isNotEmpty()) {
                                item {
                                    SectionHeader("All Projects")
                                }
                                items(otherProjects, key = { it.id }) { project ->
                                    ProjectItem(
                                        project = project,
                                        onClick = { viewModel.onProjectSelected(project) },
                                    )
                                }
                            }
                        }

                        if (state.isLoading) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center,
                            ) {
                                CircularProgressIndicator()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

@Composable
private fun ProjectItem(project: Project, onClick: () -> Unit) {
    Text(
        text = project.title,
        style = MaterialTheme.typography.bodyLarge,
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
    )
}
