# Getting Started guide: From Zero to Resilient 🚀

If you are tired of your app crashing because of a 404 or freezing because the API returned a massive 10MB JSON, you're in the right place. This guide covers how to set up Network Kit properly.

## 📦 Setting the Foundation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  network_kit: ^0.0.1
```

## 🏗️ Step 1: Initialize the Client

The `NetworkClient` is the brain of your network layer. In a production app, you should initialize this as a Singleton or via a dependency injection tool like `GetIt`.

```dart
final client = NetworkClient(
  baseUrl: 'https://api.myapp.com',
  // Providing storage enables the 'Offline Vault' automatically
  storage: OfflineStorage(), 
  // This callback is called before EVERY request.
  // Perfect for refreshing tokens from secure storage.
  getToken: () async => await mySecurePrefs.read('token'),
);
```

## 🔄 Step 2: The Connectivity Watchdog

Networking isn't just about making requests; it's about handling the *restoration* of signal. The `SyncManager` watches the device's radios and clears your offline queue the moment valid internet returns.

```dart
void main() {
  // 1. Initialize your client
  // 2. Start the watchdog
  SyncManager(client).startMonitoring();
  
  runApp(const MyApp());
}
```

## ⚡ Step 3: Making Functional Requests

We hate `try-catch`. They make code indentation deep and scary. Network Kit returns a `NetworkResult`, forcing you to handle errors safely.

### The Success Path
```dart
final result = await client.request<Map<String, dynamic>>(
  path: '/profile',
  method: HttpMethod.get,
);

if (result is Success) {
  final user = (result as Success).data;
  // Do something with user
}
```

### The Clean Way (Pattern Matching)
Since Dart 3, you should use `switch` for the most readable code:

```dart
switch (result) {
  case Success(data: final data):
    _showProfile(data);
    
  case Failure(statusCode: 499):
    _notifyUser("You're offline, but we've got your back! Changes will sync soon.");
    
  case Failure(message: final msg):
    _showErrorSnackBar(msg);
}
```

## 🧪 Advanced: Why 499?

In Network Kit, HTTP Status **499** is a custom signal. It means the request was **intercepted and persisted to the Vault**. 

When you see a 499:
1. The request was a mutation (POST, PUT, etc.).
2. There was no internet connection.
3. The request data was successfully serialized and saved to disk.

Treat 499 as a **"Success for the future"** rather than a failure.

---

[Next: Architecture Deep Dive →](architecture.md)
