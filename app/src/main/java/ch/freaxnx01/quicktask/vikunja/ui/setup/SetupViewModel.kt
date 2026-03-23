package ch.freaxnx01.quicktask.vikunja.ui.setup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import ch.freaxnx01.quicktask.vikunja.data.SecureStorage
import ch.freaxnx01.quicktask.vikunja.data.VikunjaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SetupUiState(
    val instanceUrl: String = "",
    val apiToken: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val isConnected: Boolean = false,
)

@HiltViewModel
class SetupViewModel @Inject constructor(
    private val secureStorage: SecureStorage,
    private val repository: VikunjaRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(SetupUiState(
        instanceUrl = secureStorage.instanceUrl ?: "",
        apiToken = secureStorage.apiToken ?: "",
    ))
    val uiState: StateFlow<SetupUiState> = _uiState

    fun onInstanceUrlChanged(url: String) {
        _uiState.value = _uiState.value.copy(instanceUrl = url, error = null)
    }

    fun onApiTokenChanged(token: String) {
        _uiState.value = _uiState.value.copy(apiToken = token, error = null)
    }

    fun connect() {
        val state = _uiState.value
        if (state.instanceUrl.isBlank() || state.apiToken.isBlank()) {
            _uiState.value = state.copy(error = "Both fields are required")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)

            // Save credentials first so the interceptor can use them
            secureStorage.instanceUrl = state.instanceUrl
            secureStorage.apiToken = state.apiToken

            val valid = repository.validateCredentials()
            if (valid) {
                _uiState.value = _uiState.value.copy(isLoading = false, isConnected = true)
            } else {
                // Clear credentials on failure
                secureStorage.instanceUrl = null
                secureStorage.apiToken = null
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Connection failed. Check your URL and API token.",
                )
            }
        }
    }
}
