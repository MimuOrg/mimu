package com.example.mimubeta02

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AudioManagerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var audioManager: AudioManager? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mimu.audio")
        channel.setMethodCallHandler(this)
        audioManager = binding.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSpeakerphoneOn" -> {
                val on = call.argument<Boolean>("on") ?: false
                audioManager?.isSpeakerphoneOn = on
                result.success(true)
            }
            "isSpeakerphoneOn" -> {
                val isOn = audioManager?.isSpeakerphoneOn ?: false
                result.success(isOn)
            }
            "setAudioMode" -> {
                val mode = call.argument<String>("mode") ?: "normal"
                val modeInt = when (mode) {
                    "speaker" -> AudioManager.MODE_IN_COMMUNICATION
                    "earpiece" -> AudioManager.MODE_IN_CALL
                    "bluetooth" -> AudioManager.MODE_IN_COMMUNICATION
                    else -> AudioManager.MODE_NORMAL
                }
                audioManager?.mode = modeInt
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

