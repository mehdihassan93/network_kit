# Architecture Deep Dive: Building for Resilience 🏗️

Network Kit is not a library; it's a **strategy**. Every line of code exists to protect the two most valuable things in your app: **The User's Data** and **The UI's Performance**.

## The Defensive Layers

### Layer 1: The Optimized Core
Most networking libraries block the UI thread during JSON parsing. We fixed that.
- **Background Isolates**: Every response is decoded using `compute()`. Even if your API returns a 5MB JSON object, your Flutter animations will stay at a fluid 60-120 FPS.
- **Strict Mapping**: We don't throw exceptions. We catch them at the boundary and map them to `Failure` types with human-readable reasons (Timeouts, Socket errors, etc).

### Layer 2: The Guard Interceptors
This layer acts as a filter for every outgoing and incoming byte.
- **Pull-Based Auth**: Instead of passing a static token, you pass a callback. We pull the token *milliseconds* before the request leaves the device.
- **Smart Backoff**: Retrying a `400 Bad Request` is a waste of battery. We only retry transient timeouts.

### Layer 3: The Vault (Persistence Engine)
This is where Network Kit differs from a standard wrapper.
- **FIFO Guarantee**: We preserve the order of user actions. If a user "Creates an Account" then "Updates a Profile" while offline, we replay them in that exact order once they get signal.
- **O(n/5) Efficiency**: Writing to disk is expensive. We batch the synchronization process to update the database every 5 items, reducing battery drain and storage wear.

## 🤝 Design Trade-offs & Decisions

We made some hard choices during development. Here is the logic:

### ❌ Why no FormData support in the Vault?
We explicitly exclude `FormData` from the offline queue. Why?
1. **Invalid Paths**: If you select an image from the gallery, save the path, and the app restarts, that temporary path might be purged by the OS. Replaying the request would fail.
2. **Persistence Overhead**: Serializing a 10MB image into `SharedPreferences` as a base64 string is a recipe for an OOM (Out of Memory) crash.

### 🛡️ The 200-Item Cap
We use a circular buffer for the vault. If a user makes 300 requests offline, we drop the oldest 100.
**Reasoning**: We prioritize app stability over infinite accumulation. A 200-item queue is massive enough for 99% of use cases while keeping `SharedPreferences` search times fast.

### 🔋 Battery vs. Speed
The `SyncManager` waits for a stable connection before replaying. We don't spam the radios on "flaky" connections. We'd rather wait 30 extra seconds than drain 5% of the user's battery on failed replay attempts.

---

[Back to README](../README.md)
