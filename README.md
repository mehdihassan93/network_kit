<p align="center">
  <img src="assets/banner.png" alt="Network Kit Banner" width="100%">
</p>

# Network Kit 🚀

A robust, production-ready Flutter networking engine built on top of `dio`.  
It transforms standard HTTP requests into a **resilient, offline-first subsystem** with minimal configuration.

[![Pub.dev](https://img.shields.io/pub/v/network_kit?color=blue&style=for-the-badge)](https://pub.dev/packages/network_kit)
![License](https://img.shields.io/github/license/yourusername/network_kit?style=for-the-badge)

---

## ✨ Features

- **🛡️ Type-Safe Functional Results**: Uses Dart 3 sealed classes to return `Success` or `Failure`. No more messy try-catch blocks in your UI.
- **🔄 Smart Retries**: Automatically retries on timeouts and connection failures with exponential backoff (1s, 2s, 4s).
- **📦 Offline Queuing**: Automatically queues mutation requests (POST, PUT, etc.) when the device is offline.
- **⚡ Auto-Sync**: Automatically replays your offline queue the moment connectivity is restored.
- **🔑 Zero-Effort Auth**: Simple pull-based token injection and 401 handling.
- **💾 SharedPreferences Persistence**: The offline queue survives app restarts.
- **⚡ Background Parsing**: JSON decoding happens in separate Isolates to prevent UI jank.

---

## 🚀 Getting Started

Check out the [Quick Start Guide](docs/guides/getting_started.md) for a detailed walkthrough.

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  network_kit: ^0.0.1
```

### 2. Basic Initialization

Configure your `NetworkClient` and `SyncManager`:

```dart
// 1. Initialize Storage and Client
final storage = OfflineStorage();
final client = NetworkClient(
  baseUrl: 'https://api.example.com',
  storage: storage,
  getToken: () async => 'MY_SECURE_TOKEN',
);

// 2. Setup Sync Manager
final syncManager = SyncManager(client, storage: storage);
syncManager.startMonitoring(); // Listen for connection and auto-sync
```

---

## 🛠️ Architecture

The package is built in **specific layers** to ensure maximum stability and separation of concerns.

<p align="center">
  <img src="assets/architecture.png" alt="Architecture Diagram" width="500px">
</p>

1.  **The Core**: Clean wrapper around `dio` with robust exception mapping and background parsing.
2.  **The Guard**: Interceptors for smart retries and transparent authentication.
3.  **The Vault**: Persistent offline queuing and order-preserving synchronization (O(n/5) efficiency).

See the [Architecture Deep Dive](docs/guides/architecture.md) for more details.

---

## 🧪 Performance & Safety

Network Kit is audited for **Time and Space Complexity**:
- **Disk I/O**: Batched synchronization reduces disk writes by 80%.
- **CPU**: JSON parsing is isolated from the UI thread.
- **Memory**: Circular buffer logic keeps the offline queue capped at 200 items.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
