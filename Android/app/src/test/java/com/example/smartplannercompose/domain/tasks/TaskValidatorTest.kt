package com.example.smartplannercompose.domain.tasks

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TaskValidatorTest {
    private val validator = DefaultTaskValidator()

    @Test
    fun `valid title between min and max`() {
        assertTrue(validator.isValidTitle("a"))
        assertTrue(validator.isValidTitle("Купить молоко"))
    }

    @Test
    fun `blank and whitespace title invalid`() {
        assertFalse(validator.isValidTitle(""))
        assertFalse(validator.isValidTitle("   "))
    }

    @Test
    fun `title trimmed and longer than max invalid`() {
        val long = "a".repeat(TaskValidator.TITLE_MAX_LENGTH + 1)
        assertFalse(validator.isValidTitle(long))
        assertTrue(validator.isValidTitle("a".repeat(TaskValidator.TITLE_MAX_LENGTH)))
    }

    @Test
    fun `sanitize trims and returns null on blank`() {
        assertNull(validator.sanitize(null))
        assertNull(validator.sanitize(""))
        assertNull(validator.sanitize("   "))
        assertEquals("hi", validator.sanitize("  hi  "))
    }
}
