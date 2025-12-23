# Architecture Deep Dive 🏗️

Network Kit is designed with a **Layered Resilience Strategy**. Each layer builds upon the other to create a system that is both simple to use and incredibly hard to break.

## The Three Layers

### 1. The Core (Foundation)
The bottom layer is a thin but powerful wrapper around `dio`.
- **Background Parsing**: We use `DefaultTransformer` with a custom `jsonDecodeCallback` that runs on a background Isolate.
- **Functional Mapping**: All exceptions (Timeouts, 404s, 500s) are mapped into a unified `NetworkResult<T>` sealed class.

### 2. The Guard (Resilience)
The middle layer consists of automatic Interceptors that protect your app from transient failures.
- **Smart Retries**: On timeouts, the client automatically retries with exponential backoff (1s -> 2s -> 4s).
- **Auth Layer**: Every request pull the latest token right before being sent, ensuring you never send an expired token.

### 3. The Vault (Persistence)
The top layer provides the "Magic Trick" of offline-first apps.
- **Snapshot Interception**: If a mutation (POST/PUT/PATCH/DELETE) fails due to no internet, we snapshot the request metadata.
- **FIFO Queue**: The request is stored in `SharedPreferences`.
- **Efficient Sync**: `SyncManager` replays these requests in batches (O(n/5) efficiency) once signal returns.

## Data Integrity Policies

### FIFO (First-In-First-Out)
We strictly maintain the order of requests. If Request B depends on Request A (e.g., Create Post, then Upload Image), and Request A fails, we stop the sync process until Request A succeeds.

### Size Capping
To prevent device storage bloat, the vault is capped at **200 entries**. Once the limit is reached, the oldest (and likely most stale) request is evicted to make room for new ones.

### FormData Constraint
Currently, `FormData` (binary file uploads) is **not** queued for offline sync. This is a deliberate design choice to avoid the complexity of serializing massive files and potential file-system path invalidation upon app restart.
