package ch.freaxnx01.quicktask.vikunja.data

import ch.freaxnx01.quicktask.vikunja.model.CreateTaskRequest
import ch.freaxnx01.quicktask.vikunja.model.Project
import ch.freaxnx01.quicktask.vikunja.model.TaskResponse
import retrofit2.http.*

interface VikunjaApi {
    @GET("api/v1/projects")
    suspend fun getProjects(
        @Query("per_page") perPage: Int = 100,
        @Query("page") page: Int = 1,
    ): List<Project>

    @PUT("api/v1/projects/{id}/tasks")
    suspend fun createTask(
        @Path("id") projectId: Long,
        @Body task: CreateTaskRequest,
    ): TaskResponse
}
