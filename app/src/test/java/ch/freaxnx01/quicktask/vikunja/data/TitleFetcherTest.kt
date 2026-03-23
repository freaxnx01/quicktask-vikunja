package ch.freaxnx01.quicktask.vikunja.data

import org.junit.Assert.*
import org.junit.Test
import kotlinx.coroutines.test.runTest

class TitleFetcherTest {
    private val fetcher = TitleFetcher()

    @Test
    fun `isUrl returns true for http URLs`() {
        assertTrue(fetcher.isUrl("http://example.com"))
        assertTrue(fetcher.isUrl("https://example.com/path?q=1"))
        assertTrue(fetcher.isUrl("https://www.imdb.com/title/tt1234567/"))
    }

    @Test
    fun `isUrl returns false for plain text`() {
        assertFalse(fetcher.isUrl("hello world"))
        assertFalse(fetcher.isUrl("buy groceries"))
        assertFalse(fetcher.isUrl(""))
        assertFalse(fetcher.isUrl("ftp://files.example.com"))
    }

    @Test
    fun `resolveTaskName returns plain text as-is`() = runTest {
        assertEquals("buy groceries", fetcher.resolveTaskName("buy groceries", null))
    }

    @Test
    fun `resolveTaskName uses EXTRA_SUBJECT for URL when available`() = runTest {
        val result = fetcher.resolveTaskName(
            "https://www.imdb.com/title/tt1234567/",
            "The Movie Title"
        )
        assertEquals("The Movie Title - https://www.imdb.com/title/tt1234567/", result)
    }

    @Test
    fun `resolveTaskName trims whitespace`() = runTest {
        val result = fetcher.resolveTaskName("  buy milk  ", null)
        assertEquals("buy milk", result)
    }

    @Test
    fun `resolveTaskName uses EXTRA_SUBJECT trimmed`() = runTest {
        val result = fetcher.resolveTaskName(
            "https://example.com",
            "  Page Title  "
        )
        assertEquals("Page Title - https://example.com", result)
    }
}
