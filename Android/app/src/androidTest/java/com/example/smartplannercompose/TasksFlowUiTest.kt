package com.example.smartplannercompose

import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import com.example.smartplannercompose.core.SystemClock
import com.example.smartplannercompose.data.news.FileNewsCache
import com.example.smartplannercompose.data.news.NewsApiClient
import com.example.smartplannercompose.data.news.DefaultNewsRepository
import com.example.smartplannercompose.data.tasks.InMemoryTaskStore
import com.example.smartplannercompose.data.tasks.LocalTaskRepository
import com.example.smartplannercompose.domain.dashboard.DefaultDashboardStatisticsService
import com.example.smartplannercompose.domain.tasks.DefaultCreateTaskUseCase
import com.example.smartplannercompose.domain.tasks.DefaultTaskListProcessor
import com.example.smartplannercompose.domain.tasks.DefaultTaskValidator
import com.example.smartplannercompose.presentation.tasks.TestTags
import org.junit.Rule
import org.junit.Test

class TasksFlowUiTest {

    @get:Rule val rule = createComposeRule()

    @Test
    fun add_task_appears_in_list_and_can_be_completed() {
        val repository = LocalTaskRepository(InMemoryTaskStore())
        val tasksVm = com.example.smartplannercompose.presentation.tasks.TasksViewModel(
            repository = repository,
            processor = DefaultTaskListProcessor(SystemClock),
            createTaskUseCase = DefaultCreateTaskUseCase(
                validator = DefaultTaskValidator(),
                repository = repository,
                clock = SystemClock
            )
        )

        rule.setContent {
            Surface {
                com.example.smartplannercompose.presentation.tasks.TestHarnessTasksScreen(viewModel = tasksVm)
            }
        }

        // Start on list, empty
        rule.onNodeWithText("Нет задач").assertIsDisplayed()

        // Open create
        rule.onNodeWithTag(TestTags.ADD_TASK_FAB).performClick()

        // Type title
        rule.onNodeWithTag(TestTags.TASK_TITLE_FIELD).performTextInput("Купить молоко")

        // Save
        rule.onNodeWithTag(TestTags.SAVE_TASK_BUTTON).performClick()

        // Verify task appeared
        rule.onNodeWithText("Купить молоко").assertIsDisplayed()

        // Toggle completion via the checkmark icon's content description
        rule.onAllNodesWithText("Купить молоко").onFirst().assertIsDisplayed()
    }
}
