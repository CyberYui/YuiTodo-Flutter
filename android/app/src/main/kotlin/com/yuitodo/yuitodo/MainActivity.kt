package com.yuitodo.yuitodo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var soundPreview: SoundPreview? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        soundPreview = SoundPreview(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onPause() {
        soundPreview?.stop()
        super.onPause()
    }

    override fun onDestroy() {
        soundPreview?.dispose()
        soundPreview = null
        super.onDestroy()
    }
}
