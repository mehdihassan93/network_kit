# Getting Started with Network Kit 🚀

This guide will help you integrate **Network Kit** into your Flutter application for a robust, resilient networking experience.

## Installation

Add `network_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  network_kit:
    path: ../network_kit # Or use the pub version once published
```

## Basic Setup

### 1. Create your Client

The `NetworkClient` is your primary entry point. It handles all the heavy lifting of `dio`, including interceptors and error handling.

```dart
import 'package:network_kit/network_kit.dart';

final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  storage: OfflineStorage(), // Enables offline queuing
  getToken: () async {
    // Return your auth token here (e.g., from Flutter Secure Storage)
    return 'your_auth_token';
  },
);
```

### 2. Initialize the Sync Manager

To enable automatic re-syncing of requests made while offline, you need to use the `SyncManager`.

```dart
final syncManager = SyncManager(client);

void main() {
  syncManager.startMonitoring(); // Start listening for connectivity changes
  runApp(MyApp());
}
```

## Making Requests

Network Kit uses Dart 3 **Sealed Classes** for type-safe error handling. This means you don't need `try-catch` blocks!

```dart
Future<void> fetchUser() async {
  final result = await client.request<Map<String, dynamic>>(
    path: '/user/profile',
    method: HttpMethod.get,
  );

  switch (result) {
    case Success(data: final user):
      print('User name: ${user['name']}');
      
    case Failure(statusCode: final code, message: final msg):
      if (code == 499) {
        print('Offline! Request queued for later.');
      } else {
        print('Error: $msg');
      }
  }
}
```

## Advanced Configuration

### Custom Header Injection

You can pass an `Options` object from `dio` to the `request` method for one-off header changes:

```dart
await client.request(
  path: '/test',
  method: HttpMethod.get,
  options: Options(headers: {'Custom-Header': 'Value'}),
);
```

### Background Parsing

Network Kit automatically uses `compute()` to parse JSON responses and data. This ensures your UI stays responsive (60+ FPS) even when handling massive JSON payloads.
