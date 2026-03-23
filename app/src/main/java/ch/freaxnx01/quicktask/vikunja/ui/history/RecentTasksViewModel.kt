package ch.freaxnx01.quicktask.vikunja.ui.history

import androidx.lifecycle.ViewModel
import ch.freaxnx01.quicktask.vikunja.data.TaskHistory
import ch.freaxnx01.quicktask.vikunja.data.TaskHistoryEntry
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

@HiltViewModel
class RecentTasksViewModel @Inject constructor(
    private val taskHistory: TaskHistory,
) : ViewModel() {

    private val _entries = MutableStateFlow<List<TaskHistoryEntry>>(emptyList())
    val entries: StateFlow<List<TaskHistoryEntry>> = _entries

    init {
        refresh()
    }

    fun refresh() {
        _entries.value = taskHistory.getEntries()
    }
}
