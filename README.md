# AMLEDS (Autonomous Machine Latency Evaluation & Diagnostic System)

A network diagnostic tool for monitoring autonomous machines with static IPs on Android. Formerly known as CatTriage.

## Features

- **Machine Profiles**: Create and manage machine profiles with multiple IP addresses per machine
- **Real-time Monitoring**: Continuous ping monitoring with 1-second intervals
- **Visual Status Indicators**: 
  - 🟢 Green: Excellent (< 50ms)
  - 🟡 Yellow: Fair (50-200ms)
  - 🟠 Orange: Poor (> 200ms)
  - 🔴 Red: Timeout/no response
- **Rolling History**: Display last 10 readings per IP address (configurable)
- **Customizable Thresholds**: Adjust latency thresholds in settings
- **No Audio Alerts**: Visual-only status updates

## Screenshots

The app includes:
- Main screen with list of saved machines
- Add/Edit machine screen for managing machine profiles
- Monitor screen with real-time ping status and history charts
- Settings screen for configuring thresholds

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- Android SDK (API level 21 or higher)

## Setup Instructions

### 1. Clone or Extract the Project

```bash
cd amleds
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Android (if needed)

The project includes Android configuration files. If you need to update the Flutter SDK path:

Create or edit `android/local.properties`:
```properties
flutter.sdk=/path/to/your/flutter/sdk
```

### 4. Build the APK

For a debug build:
```bash
flutter build apk --debug
```

For a release build:
```bash
flutter build apk --release
```

The APK will be located at:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Install on Device

```bash
flutter install
```

Or manually install the APK:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Usage

1. **Add a Machine**: Tap the "Add Machine" button on the main screen
2. **Configure Machine**: Enter a name and add one or more IP addresses
3. **Monitor**: Tap on a machine to start monitoring
4. **View Status**: Watch real-time ping results with color-coded status
5. **Adjust Settings**: Use the settings icon to customize thresholds

## Project Structure

```
amleds/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/
│   │   ├── machine.dart               # Machine data model
│   │   ├── ping_result.dart           # Ping result data model
│   │   └── settings.dart              # App settings model
│   ├── services/
│   │   ├── storage_service.dart       # JSON persistence
│   │   └── ping_service.dart          # Ping implementation
│   ├── screens/
│   │   ├── machine_list_screen.dart   # Main machine list
│   │   ├── machine_edit_screen.dart   # Add/Edit machine
│   │   ├── monitor_screen.dart        # Real-time monitoring
│   │   └── settings_screen.dart       # Threshold configuration
│   └── widgets/
│       ├── status_indicator.dart      # Status UI components
│       └── ping_history_chart.dart    # History visualization
├── android/                           # Android configuration
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

## Dependencies

- `dart_ping`: ^9.0.1 - ICMP ping functionality
- `dart_ping_ios`: ^4.0.0 - iOS ping support (included for compatibility)
- `shared_preferences`: ^2.2.2 - Settings storage
- `path_provider`: ^2.1.1 - File system access

## Permissions

The app requires the following Android permissions:
- `INTERNET` - For sending ping requests
- `ACCESS_NETWORK_STATE` - For network state monitoring

## Troubleshooting

### Build Issues

1. **Flutter SDK not found**: Ensure `flutter` is in your PATH or set `flutter.sdk` in `android/local.properties`

2. **Gradle sync issues**: Try:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

3. **Dependency conflicts**: Run `flutter pub upgrade` to update dependencies

### Runtime Issues

1. **Ping not working**: Some Android devices may require root access for ICMP pings. The app uses the `dart_ping` package which handles most cases.

2. **No network access**: Ensure the app has internet permission and the device is connected to a network.

## License

This project is provided as-is for network diagnostic purposes.

## Contributing

Feel free to fork and modify for your specific needs.
