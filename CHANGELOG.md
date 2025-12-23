# Changelog

## 0.0.1

- **Initial Release**: A robust, production-ready networking engine for Flutter.
- **Sealed Result Types**: Implemented `NetworkResult` (Success/Failure) for type-safe API handling.
- **Resilient Layering**: 
    - **Core**: `NetworkClient` with background JSON parsing (compute) and centralized `ExceptionHandler`.
    - **Guard**: `RetryInterceptor` with exponential backoff and `AuthInterceptor` for pull-based token injection.
    - **Vault**: `OfflineStorage` with 200-item cap and `QueueInterceptor` for offline persistence.
- **Sync Engine**: `SyncManager` with auto-monitoring and batched I/O synchronization (O(n/5)).
- **Documentation**: Extensive docstrings across the public API.
- **Example**: Full-featured example app demonstrating the offline-to-online sync loop.
- **Tests**: Comprehensive unit, integration, and widget test suite.
