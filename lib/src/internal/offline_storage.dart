import 'package:shared_preferences/shared_preferences.dart';

/// Handles the persistence of offline request metadata using SharedPreferences.
class OfflineStorage {
  static const String _queueKey = 'network_kit_queue';
  static const int _maxQueueSize = 200;

  SharedPreferences? _prefs;

  /// Lazy instance of SharedPreferences.
  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Appends a request to the end of the queue. 
  /// Drops the oldest request if the size exceeds [_maxQueueSize].
  Future<void> saveRequest(String jsonRequest) async {
    final prefs = await _instance;
    final queue = prefs.getStringList(_queueKey) ?? [];
    
    if (queue.length >= _maxQueueSize) {
      queue.removeAt(0);
    }
    
    queue.add(jsonRequest);
    await prefs.setStringList(_queueKey, queue);
  }

  /// Overwrites the entire queue. Used for batched sync operations.
  Future<void> saveQueue(List<String> queue) async {
    final prefs = await _instance;
    await prefs.setStringList(_queueKey, queue);
  }

  /// Fetches the current list of serialized requests.
  /// Returns an empty list if storage is corrupted or empty.
  Future<List<String>> getQueue() async {
    try {
      final prefs = await _instance;
      final queue = prefs.getStringList(_queueKey);
      if (queue == null) return [];
      
      // Basic validation: ensure each item is at least a non-empty string.
      return queue.where((item) => item.isNotEmpty).toList();
    } catch (_) {
      // In case of drastic corruption, clear and return empty.
      await clearQueue();
      return [];
    }
  }

  /// Deletes a specific request from the persistent store.
  Future<void> removeRequest(String jsonRequest) async {
    final prefs = await _instance;
    final queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.remove(jsonRequest)) {
      await prefs.setStringList(_queueKey, queue);
    }
  }

  /// Wipes all pending requests.
  Future<void> clearQueue() async {
    final prefs = await _instance;
    await prefs.remove(_queueKey);
  }
}
