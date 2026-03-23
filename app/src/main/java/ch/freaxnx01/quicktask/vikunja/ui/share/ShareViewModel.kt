package ch.freaxnx01.quicktask.vikunja.ui.share

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import ch.freaxnx01.quicktask.vikunja.data.ProjectUsageTracker
import ch.freaxnx01.quicktask.vikunja.data.TaskHistory
import ch.freaxnx01.quicktask.vikunja.data.TaskHistoryEntry
import ch.freaxnx01.quicktask.vikunja.data.TitleFetcher
import ch.freaxnx01.quicktask.vikunja.data.VikunjaRepository
import ch.freaxnx01.quicktask.vikunja.model.Project
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ShareUiState(
    val taskName: String = "",
    val projects: List<Project> = emptyList(),
    val searchQuery: String = "",
    val isLoading: Boolean = true,
    val error: String? = null,
    val isDone: Boolean = false,
    val addedToProject: String? = null,
)

@HiltViewModel
class ShareViewModel @Inject constructor(
    private val savedStateHandle: SavedStateHandle,
    private val repository: VikunjaRepository,
    private val titleFetcher: TitleFetcher,
    private val projectUsageTracker: ProjectUsageTracker,
    private val taskHistory: TaskHistory,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ShareUiState())
    val uiState: StateFlow<ShareUiState> = _uiState

    private var allProjects: List<Project> = emptyList()

    fun initialize(sharedText: String, extraSubject: String?) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Resolve task name
            val taskName = try {
                titleFetcher.resolveTaskName(sharedText, extraSubject)
            } catch (_: Exception) {
                sharedText
            }

            // Fetch projects
            val projects = try {
                repository.getAllProjects()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to load projects: ${e.message}",
                    taskName = taskName,
                )
                return@launch
            }

            allProjects = projects
            _uiState.value = _uiState.value.copy(
                taskName = taskName,
                projects = sortProjects(projects),
                isLoading = false,
            )
        }
    }

    fun onSearchQueryChanged(query: String) {
        _uiState.value = _uiState.value.copy(
            searchQuery = query,
            projects = filterAndSortProjects(allProjects, query),
        )
    }

    fun onProjectSelected(project: Project) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            try {
                repository.createTask(project.id, _uiState.value.taskName)
                projectUsageTracker.recordUsage(project.id)
                taskHistory.addEntry(
                    TaskHistoryEntry(
                        taskName = _uiState.value.taskName,
                        projectName = project.title,
                        timestamp = System.currentTimeMillis(),
                    )
                )
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    isDone = true,
                    addedToProject = project.title,
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to create task: ${e.message}",
                )
            }
        }
    }

    private fun sortProjects(projects: List<Project>): List<Project> {
        val recentIds = projectUsageTracker.getRecentProjectIds()
        val recentProjects = recentIds.mapNotNull { id -> projects.find { it.id == id } }
        val remainingProjects = projects.filter { it.id !in recentIds }.sortedBy { it.title.lowercase() }
        return recentProjects + remainingProjects
    }

    private fun filterAndSortProjects(projects: List<Project>, query: String): List<Project> {
        if (query.isBlank()) return sortProjects(projects)
        val filtered = projects.filter { it.title.contains(query, ignoreCase = true) }
        return sortProjects(filtered)
    }

    fun getRecentProjectIds(): List<Long> = projectUsageTracker.getRecentProjectIds()
}
