import AVFoundation
import Flutter

public class AudioManagerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mimu.audio", binaryMessenger: registrar.messenger())
        let instance = AudioManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setSpeakerphoneOn":
            guard let args = call.arguments as? [String: Any],
                  let on = args["on"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: on ? .defaultToSpeaker : [])
                try audioSession.setActive(true)
                result(true)
            } catch {
                result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
            }
        case "isSpeakerphoneOn":
            let audioSession = AVAudioSession.sharedInstance()
            let isSpeakerphoneOn = audioSession.currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
            result(isSpeakerphoneOn)
        case "setAudioMode":
            guard let args = call.arguments as? [String: Any],
                  let mode = args["mode"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            do {
                let audioSession = AVAudioSession.sharedInstance()
                var options: AVAudioSession.CategoryOptions = []
                switch mode {
                case "speaker":
                    options = .defaultToSpeaker
                case "bluetooth":
                    options = .allowBluetooth
                default:
                    options = []
                }
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: options)
                try audioSession.setActive(true)
                result(true)
            } catch {
                result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

