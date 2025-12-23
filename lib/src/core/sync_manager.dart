import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_client.dart';
import '../internal/offline_storage.dart';
import '../models/network_result.dart';

/// **SyncManager** is the engine responsible for replaying requests that were 
/// failed and queued while the device was offline.
class SyncManager {
  /// The [NetworkClient] used to re-execute the requests.
  final NetworkClient client;
  
  /// The [OfflineStorage] where temporary requests are persisted.
  final OfflineStorage storage;

  /// Subscription to track connectivity status changes.
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Creates a [SyncManager].
  SyncManager(this.client, {OfflineStorage? storage}) 
      : storage = storage ?? OfflineStorage();

  /// Starts monitoring connectivity status to automatically trigger sync.
  void startMonitoring() {
    _subscription?.cancel(); 
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        startSync();
      }
    });
  }

  /// Stops listening for connectivity changes.
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// **Refactored: Optimized Batched Synchronization**
  ///
  /// This method uses a "Memory-First" approach to reduce disk I/O from 
  /// O(n) to O(n/5), while maintaining crash safety via periodic batch saves.
  Future<void> startSync() async {
    // 1. Load the entire queue once into memory
    final queue = await storage.getQueue();
    if (queue.isEmpty) return;

    // Create a mutable copy for in-memory processing
    final memoryQueue = List<String>.from(queue);
    int processedCount = 0;

    // 2. Process items sequentially to ensure FIFO order
    for (final jsonRequest in queue) {
      try {
        final Map<String, dynamic> requestMap = jsonDecode(jsonRequest) as Map<String, dynamic>;
        
        // 3. Replay the request
        final result = await client.request(
          path: requestMap['path'] as String,
          method: _parseMethod(requestMap['method'] as String),
          data: requestMap['data'],
          queryParameters: (requestMap['queryParameters'] as Map?)?.cast<String, dynamic>(),
        );

        if (result is Success) {
          // 4. Update memory state
          memoryQueue.remove(jsonRequest);
          processedCount++;

          // 5. Batch Safety: Save to disk every 5 items to balance speed and data integrity
          if (processedCount % 5 == 0) {
            await storage.saveQueue(memoryQueue);
          }
        } else {
          // Failure (still offline): Stop to preserve order for the next attempt
          break;
        }
      } catch (_) {
        // Data corruption: remove this specific item and continue
        memoryQueue.remove(jsonRequest);
      }
    }

    // 6. Final Sync: Ensure the disk matches our final memory state
    await storage.saveQueue(memoryQueue);
  }

  /// Translates a string method name back to a [HttpMethod] enum.
  HttpMethod _parseMethod(String method) {
    return HttpMethod.values.firstWhere(
      (m) => m.name.toLowerCase() == method.toLowerCase(),
      orElse: () => HttpMethod.post,
    );
  }
}
