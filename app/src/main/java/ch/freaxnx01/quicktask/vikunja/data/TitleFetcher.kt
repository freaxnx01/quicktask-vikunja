package ch.freaxnx01.quicktask.vikunja.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jsoup.Jsoup
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TitleFetcher @Inject constructor() {
    companion object {
        private val URL_PATTERN = Regex("^https?://\\S+$", RegexOption.IGNORE_CASE)
        private const val TIMEOUT_MS = 5000
    }

    fun isUrl(text: String): Boolean = URL_PATTERN.matches(text.trim())

    suspend fun resolveTaskName(sharedText: String, extraSubject: String?): String {
        val text = sharedText.trim()
        if (!isUrl(text)) return text

        if (!extraSubject.isNullOrBlank()) {
            return "${extraSubject.trim()} - $text"
        }

        return withContext(Dispatchers.IO) {
            try {
                val title = Jsoup.connect(text)
                    .timeout(TIMEOUT_MS)
                    .get()
                    .title()
                if (title.isNullOrBlank()) text else "$title - $text"
            } catch (_: Exception) {
                text
            }
        }
    }
}
