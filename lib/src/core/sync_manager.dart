import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'network_client.dart';
import '../internal/offline_storage.dart';
import '../models/network_result.dart';

/// Manages the re-execution of failed requests when connectivity is restored.
class SyncManager {
  /// Initializes the manager with a network client and optional storage.
  SyncManager(this.client, {OfflineStorage? storage}) 
      : storage = storage ?? OfflineStorage();

  /// The network client used for replaying requests.
  final NetworkClient client;
  /// The storage mechanism for the offline queue.
  final OfflineStorage storage;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  /// Listens for connectivity changes and triggers a sync when back online.
  void startMonitoring() {
    _subscription?.cancel(); 
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        startSync();
      }
    });
  }

  /// Stops monitoring connectivity changes.
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Processes the offline queue sequentially to maintain request order.
  /// Uses a batch-saving strategy to minimize disk I/O while keeping data safe.
  Future<void> startSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await storage.getQueue();
      if (queue.isEmpty) return;

    final memoryQueue = List<String>.from(queue);
    int processedCount = 0;

    for (final jsonRequest in queue) {
      try {
        final Map<String, dynamic> requestMap = jsonDecode(jsonRequest) as Map<String, dynamic>;
        
        // Re-execute the request
        final result = await client.request<dynamic>(
          path: requestMap['path'] as String,
          method: _parseMethod(requestMap['method'] as String),
          data: requestMap['data'],
          queryParameters: (requestMap['queryParameters'] as Map?)?.cast<String, dynamic>(),
          options: Options(
            headers: (requestMap['headers'] as Map?)?.cast<String, dynamic>(),
            extra: {'skipQueue': true},
          ),
        );

        if (result is Success) {
          memoryQueue.remove(jsonRequest);
          processedCount++;

          // Periodically save progress to disk to prevent data loss on crash.
          if (processedCount % 5 == 0) {
            await storage.saveQueue(memoryQueue);
          }
        } else {
          // If we're still offline or the server fails, stop to preserve order.
          // Note: Logic errors (4xx) should technically be handled or skipped, 
          // but for now we stop to be safe.
          break;
        }
      } catch (_) {
        // Drop corrupted items to keep the queue moving.
        memoryQueue.remove(jsonRequest);
      }
    }

    // Final persistent save of the remaining queue state.
    await storage.saveQueue(memoryQueue);
    } finally {
      _isSyncing = false;
    }
  }

  /// Helpers to convert string method names back to enums.
  HttpMethod _parseMethod(String method) {
    return HttpMethod.values.firstWhere(
      (m) => m.name.toLowerCase() == method.toLowerCase(),
      orElse: () => HttpMethod.post,
    );
  }
}
