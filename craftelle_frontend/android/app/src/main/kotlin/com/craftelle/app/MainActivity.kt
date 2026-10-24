package com.craftelle.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Draw behind system bars on all Android versions, matching Android 15+ behaviour
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
