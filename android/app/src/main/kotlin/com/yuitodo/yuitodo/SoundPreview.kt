package com.yuitodo.yuitodo

import android.content.Context
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plays a short preview of a reminder sound.
 *
 * Only one [MediaPlayer] exists at a time: starting a new preview stops and
 * releases the previous one, so rapid taps cannot mix audio. A token guards
 * against a stale completion callback clearing the state of a newer preview.
 */
internal class SoundPreview(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL)
    private var player: MediaPlayer? = null
    private var token = 0

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                val nextToken = call.argument<Int>("token") ?: 0
                val raw = call.argument<String>("raw")
                play(raw, nextToken)
                result.success(true)
            }
            "stop" -> {
                stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun play(raw: String?, nextToken: Int) {
        stop()
        token = nextToken
        val created = try {
            if (raw != null) {
                val resId = appContext.resources.getIdentifier(raw, "raw", appContext.packageName)
                if (resId == 0) {
                    Log.w(TAG, "raw resource not found: $raw")
                    null
                } else {
                    MediaPlayer.create(appContext, resId)
                }
            } else {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                if (uri == null) null else MediaPlayer.create(appContext, uri)
            }
        } catch (e: Exception) {
            Log.w(TAG, "create failed for raw=$raw", e)
            null
        }

        if (created == null) {
            channel.invokeMethod("onComplete", nextToken)
            return
        }

        player = created
        created.setOnCompletionListener { finish(nextToken) }
        created.setOnErrorListener { _, what, extra ->
            Log.w(TAG, "player error what=$what extra=$extra")
            finish(nextToken)
            true
        }
        try {
            created.start()
            Log.d(TAG, "play raw=$raw token=$nextToken")
        } catch (e: Exception) {
            Log.w(TAG, "start failed", e)
            finish(nextToken)
        }
    }

    private fun finish(finishedToken: Int) {
        if (finishedToken != token) return
        releasePlayer()
        channel.invokeMethod("onComplete", finishedToken)
        Log.d(TAG, "complete token=$finishedToken")
    }

    fun stop() {
        val hadPlayer = player != null
        token++
        releasePlayer()
        if (hadPlayer) Log.d(TAG, "stop")
    }

    private fun releasePlayer() {
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
    }

    fun dispose() {
        stop()
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val TAG = "YuiTodoSoundPreview"
        private const val CHANNEL = "com.yuitodo/sound_preview"
    }
}
