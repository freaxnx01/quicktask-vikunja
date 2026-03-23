package ch.freaxnx01.quicktask.vikunja.data

import ch.freaxnx01.quicktask.vikunja.model.CreateTaskRequest
import ch.freaxnx01.quicktask.vikunja.model.Project
import ch.freaxnx01.quicktask.vikunja.model.TaskResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VikunjaRepository @Inject constructor(
    private val api: VikunjaApi,
) {
    suspend fun validateCredentials(): Boolean {
        return try {
            api.getProjects(perPage = 1)
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun getAllProjects(): List<Project> {
        val allProjects = mutableListOf<Project>()
        var page = 1
        while (true) {
            val batch = api.getProjects(perPage = 100, page = page)
            allProjects.addAll(batch)
            if (batch.size < 100) break
            page++
        }
        return allProjects.filter { !it.isArchived }
    }

    suspend fun createTask(projectId: Long, title: String): TaskResponse {
        return api.createTask(projectId, CreateTaskRequest(title))
    }
}
