package com.example.smartplannercompose.domain.tasks

interface TaskValidator {
    fun isValidTitle(title: String): Boolean
    fun sanitize(text: String?): String?

    companion object {
        const val TITLE_MIN_LENGTH = 1
        const val TITLE_MAX_LENGTH = 80
    }
}

class DefaultTaskValidator : TaskValidator {
    override fun isValidTitle(title: String): Boolean {
        val trimmed = title.trim()
        return trimmed.length in TaskValidator.TITLE_MIN_LENGTH..TaskValidator.TITLE_MAX_LENGTH
    }

    override fun sanitize(text: String?): String? {
        if (text == null) return null
        val trimmed = text.trim()
        return trimmed.ifEmpty { null }
    }
}
