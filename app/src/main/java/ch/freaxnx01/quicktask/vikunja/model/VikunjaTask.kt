package ch.freaxnx01.quicktask.vikunja.model

import kotlinx.serialization.Serializable

@Serializable
data class CreateTaskRequest(val title: String)

@Serializable
data class TaskResponse(val id: Long, val title: String)
