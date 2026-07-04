package com.example.smartplannercompose.data.tasks

import android.content.SharedPreferences
import com.example.smartplannercompose.domain.tasks.Task
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

interface TaskStore {
    fun load(): List<Task>
    fun save(tasks: List<Task>)
}

class InMemoryTaskStore(initial: List<Task> = emptyList()) : TaskStore {
    private var state: List<Task> = initial
    override fun load(): List<Task> = state
    override fun save(tasks: List<Task>) { state = tasks }
}

class SharedPreferencesTaskStore(
    private val preferences: SharedPreferences,
    private val gson: Gson = Gson()
) : TaskStore {

    private val type = object : TypeToken<List<Task>>() {}.type

    override fun load(): List<Task> {
        val raw = preferences.getString(KEY, null) ?: return emptyList()
        return runCatching { gson.fromJson<List<Task>>(raw, type) ?: emptyList() }
            .getOrDefault(emptyList())
    }

    override fun save(tasks: List<Task>) {
        preferences.edit().putString(KEY, gson.toJson(tasks)).apply()
    }

    private companion object {
        const val KEY = "SmartPlanner.tasks.v1"
    }
}
