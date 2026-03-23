package ch.freaxnx01.quicktask.vikunja

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import ch.freaxnx01.quicktask.vikunja.data.SecureStorage
import ch.freaxnx01.quicktask.vikunja.ui.setup.SetupScreen
import ch.freaxnx01.quicktask.vikunja.ui.theme.QuickTaskTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var secureStorage: SecureStorage

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            QuickTaskTheme {
                var showSetup by remember { mutableStateOf(!secureStorage.isConfigured) }

                if (showSetup) {
                    SetupScreen(onConnected = { showSetup = false })
                } else {
                    // Placeholder until Task 7 creates RecentTasksScreen
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("Recent Tasks (coming soon)")
                    }
                }
            }
        }
    }
}
