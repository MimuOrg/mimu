# Platform Channels Setup

## Android

1. **Plugin Location**: `android/app/src/main/kotlin/com/example/mimubeta02/AudioManagerPlugin.kt`
2. **Registration**: Already registered in `MainActivity.kt`
3. **Permissions**: Add to `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
   ```

## iOS

1. **Plugin Location**: `ios/Runner/AudioManagerPlugin.swift`
2. **Registration**: Already registered in `AppDelegate.swift`
3. **Info.plist**: Add audio session usage description:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Mimu needs microphone access for calls</string>
   ```

## Usage in Flutter

```dart
import 'package:mimu/features/calls/audio_manager.dart';

// Enable speakerphone
await AudioManager.setSpeakerphoneOn(true);

// Check current state
final isOn = await AudioManager.isSpeakerphoneOn();

// Set audio mode
await AudioManager.setAudioMode('speaker'); // or 'earpiece', 'bluetooth', 'normal'
```

## Testing

- Test on real device (emulators may not support audio routing)
- Verify speakerphone toggle works during active call
- Test Bluetooth headset switching

