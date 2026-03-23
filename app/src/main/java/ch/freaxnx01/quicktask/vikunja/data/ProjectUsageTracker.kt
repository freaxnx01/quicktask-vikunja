package ch.freaxnx01.quicktask.vikunja.data

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProjectUsageTracker @Inject constructor(@ApplicationContext context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("project_usage", Context.MODE_PRIVATE)

    fun recordUsage(projectId: Long) {
        prefs.edit().putLong("project_$projectId", System.currentTimeMillis()).apply()
    }

    fun getRecentProjectIds(limit: Int = 5): List<Long> {
        return prefs.all
            .filter { it.key.startsWith("project_") }
            .mapNotNull { (key, value) ->
                val id = key.removePrefix("project_").toLongOrNull()
                val timestamp = value as? Long
                if (id != null && timestamp != null) id to timestamp else null
            }
            .sortedByDescending { it.second }
            .take(limit)
            .map { it.first }
    }
}
