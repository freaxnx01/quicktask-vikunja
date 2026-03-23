package ch.freaxnx01.quicktask.vikunja

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import ch.freaxnx01.quicktask.vikunja.data.SecureStorage
import ch.freaxnx01.quicktask.vikunja.ui.share.ProjectPickerScreen
import ch.freaxnx01.quicktask.vikunja.ui.share.ShareViewModel
import ch.freaxnx01.quicktask.vikunja.ui.theme.QuickTaskTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class ShareActivity : ComponentActivity() {

    @Inject lateinit var secureStorage: SecureStorage

    private val viewModel: ShareViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // If not configured, redirect to setup
        if (!secureStorage.isConfigured) {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
            return
        }

        // Extract shared content
        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (sharedText.isNullOrBlank()) {
            finish()
            return
        }
        val extraSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)

        // Initialize the view model
        viewModel.initialize(sharedText, extraSubject)

        setContent {
            QuickTaskTheme {
                ProjectPickerScreen(
                    viewModel = viewModel,
                    onDone = { projectName ->
                        Toast.makeText(
                            this@ShareActivity,
                            "Task added to $projectName",
                            Toast.LENGTH_SHORT,
                        ).show()
                        finish()
                    },
                )
            }
        }
    }
}
