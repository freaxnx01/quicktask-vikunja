package ch.freaxnx01.quicktask.vikunja.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Project(
    val id: Long,
    val title: String,
    @SerialName("is_archived") val isArchived: Boolean = false,
)
