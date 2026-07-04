package com.example.smartplannercompose.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import com.example.smartplannercompose.ui.theme.SmartPlannerComposeTheme

class MainActivity : ComponentActivity() {

    val container: AppContainer by lazy { AppContainer(applicationContext) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            SmartPlannerComposeTheme {
                Surface(color = MaterialTheme.colorScheme.background) {
                    SmartPlannerApp(container = container)
                }
            }
        }
    }
}
