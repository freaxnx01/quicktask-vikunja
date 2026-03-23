package ch.freaxnx01.quicktask.vikunja.data

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Serializable
data class TaskHistoryEntry(
    val taskName: String,
    val projectName: String,
    val timestamp: Long,
)

@Singleton
class TaskHistory @Inject constructor(@ApplicationContext context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("task_history", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }
    private val maxEntries = 20

    fun addEntry(entry: TaskHistoryEntry) {
        val entries = getEntries().toMutableList()
        entries.add(0, entry)
        if (entries.size > maxEntries) {
            entries.subList(maxEntries, entries.size).clear()
        }
        prefs.edit().putString("entries", json.encodeToString(entries)).apply()
    }

    fun getEntries(): List<TaskHistoryEntry> {
        val raw = prefs.getString("entries", null) ?: return emptyList()
        return try {
            json.decodeFromString<List<TaskHistoryEntry>>(raw)
        } catch (_: Exception) {
            emptyList()
        }
    }
}
