import 'package:shared_preferences/shared_preferences.dart';

/// **OfflineStorage** defines the contract for persisting offline requests.
///
/// It uses `SharedPreferences` by default, but can be subclassed or mocked 
/// for testing purposes.
class OfflineStorage {
  /// The key used to store the list of serialized requests in SharedPreferences.
  static const String _queueKey = 'network_kit_queue';

  /// Maximum number of requests allowed in the queue to prevent memory bloat.
  static const int _maxQueueSize = 200;

  /// Internal SharedPreferences instance used for persistence.
  SharedPreferences? _prefs;

  /// Private helper to ensure SharedPreferences is initialized.
  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Saves a serialized request string to the end of the current queue.
  ///
  /// This implementation follows a **FIFO (First-In-First-Out)** logic.
  /// If the queue exceeds [_maxQueueSize], the oldest request is dropped.
  /// 
  /// [jsonRequest] - The JSON string representing the request metadata.
  Future<void> saveRequest(String jsonRequest) async {
    final prefs = await _instance;
    final queue = prefs.getStringList(_queueKey) ?? [];
    
    // Safety check: Remove oldest if we hit the limit
    if (queue.length >= _maxQueueSize) {
      queue.removeAt(0);
    }
    
    queue.add(jsonRequest);
    await prefs.setStringList(_queueKey, queue);
  }

  /// Saves a full list of requests to the storage at once.
  /// 
  /// This is used by the [SyncManager] for batched updates to improve 
  /// disk I/O performance (O(n/batchSize)).
  Future<void> saveQueue(List<String> queue) async {
    final prefs = await _instance;
    await prefs.setStringList(_queueKey, queue);
  }

  /// Retrieves all pending serialized requests in the order they were saved.
  ///
  /// Returns a [List<String>] where each string is a JSON-encoded request.
  Future<List<String>> getQueue() async {
    final prefs = await _instance;
    return prefs.getStringList(_queueKey) ?? [];
  }

  /// Removes a specific serialized request from the persistent storage.
  ///
  /// This is typically called by the [SyncManager] after a request has 
  /// been successfully replayed to the server.
  ///
  /// [jsonRequest] - The exact string content to be removed.
  Future<void> removeRequest(String jsonRequest) async {
    final prefs = await _instance;
    final queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.remove(jsonRequest)) {
      await prefs.setStringList(_queueKey, queue);
    }
  }

  /// Completely wipes the offline queue.
  Future<void> clearQueue() async {
    final prefs = await _instance;
    await prefs.remove(_queueKey);
  }
}
