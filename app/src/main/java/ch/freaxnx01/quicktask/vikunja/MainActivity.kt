package ch.freaxnx01.quicktask.vikunja

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import ch.freaxnx01.quicktask.vikunja.data.SecureStorage
import ch.freaxnx01.quicktask.vikunja.ui.history.RecentTasksScreen
import ch.freaxnx01.quicktask.vikunja.ui.setup.SetupScreen
import ch.freaxnx01.quicktask.vikunja.ui.theme.QuickTaskTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var secureStorage: SecureStorage

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            QuickTaskTheme {
                var showSetup by remember { mutableStateOf(!secureStorage.isConfigured) }

                if (showSetup) {
                    SetupScreen(
                        onConnected = { showSetup = false },
                    )
                } else {
                    RecentTasksScreen(
                        onSettingsClick = { showSetup = true },
                    )
                }
            }
        }
    }
}
