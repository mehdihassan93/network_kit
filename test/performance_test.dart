// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
class MockNetworkClient extends Mock implements NetworkClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Network Kit Stress & Complexity Tests', () {
    late OfflineStorage storage;
    late MockNetworkClient mockClient;
    late SyncManager syncManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = OfflineStorage();
      mockClient = MockNetworkClient();
      syncManager = SyncManager(mockClient, storage: storage);
    });

    test('Memory Stress: 1,000 Requests Queuing', () async {
      final watch = Stopwatch()..start();
      
      // Payload: ~500 bytes per request
      final largePayload = {
        'id': 'test-uuid-001',
        'data': 'A' * 400, // 400 chars
        'timestamp': DateTime.now().toIso8601String(),
      };
      final jsonPayload = jsonEncode({
        'path': '/api/test',
        'method': 'post',
        'data': largePayload,
      });

      print('--- Memory Stress Test ---');
      for (int i = 0; i < 1000; i++) {
        await storage.saveRequest(jsonPayload);
      }
      
      final queue = await storage.getQueue();
      watch.stop();

      print('Time to queue 1,000 requests: ${watch.elapsedMilliseconds}ms');
      print('Queue size in memory: ${queue.length} items');
      
      // Since we updated OfflineStorage to cap at 200, the result should be 200
      expect(queue.length, 200);
    });

    test('CPU Stress: Large JSON Parsing (5MB)', () async {
      print('\n--- CPU Stress Test ---');
      // Create a 5MB JSON String
      final bigStringBuffer = StringBuffer('{ "data": [');
      for (int i = 0; i < 50000; i++) {
        bigStringBuffer.write('{ "id": $i, "value": "some test data representing a large response" }');
        if (i < 49999) bigStringBuffer.write(',');
      }
      bigStringBuffer.write('] }');
      final rawJson = bigStringBuffer.toString();
      
      print('Generated 5MB JSON string. Size: ${rawJson.length / (1024 * 1024)} MB');

      final watch = Stopwatch()..start();
      // Simulating what happens inside NetworkClient or decoding
      final decoded = jsonDecode(rawJson);
      watch.stop();

      print('Decoding time (Main Thread): ${watch.elapsedMilliseconds}ms');
      
      // If decoding takes more than 16ms, it will drop a frame in a real Flutter app.
      if (watch.elapsedMilliseconds > 16) {
        print('⚠️ WARNING: 5MB JSON decoding took > 16ms. This will block the UI thread.');
      }
      
      expect(decoded, isA<Map<dynamic, dynamic>>());
    });

    test('Throughput: Syncing 1,000 Requests (O(n2) Risk)', () async {
      print('\n--- Throughput Stress Test ---');
      
      // Pre-fill storage with 1,000 requests (it will cap at 200)
      final jsonPayload = jsonEncode({
        'path': '/api/test',
        'method': 'post',
        'data': {'test': 'data'},
      });
      for (int i = 0; i < 1000; i++) {
        await storage.saveRequest(jsonPayload);
      }

      // Mock Success for all replays
      when(() => mockClient.request<dynamic>(
        path: any<String>(named: 'path'),
        method: any<HttpMethod>(named: 'method'),
        data: any<dynamic>(named: 'data'),
        queryParameters: any<Map<String, dynamic>?>(named: 'queryParameters'),
      )).thenAnswer((_) async => const Success<dynamic>({'status': 'ok'}));

      final watch = Stopwatch()..start();
      await syncManager.startSync();
      watch.stop();

      print('Total Sync time for 200 items (capped): ${watch.elapsedMilliseconds}ms');
      print('Average time per item: ${watch.elapsedMilliseconds / 200}ms');
      
      final queue = await storage.getQueue();
      expect(queue.length, 0);

      if (watch.elapsedMilliseconds > 1000) {
        print('⚠️ CRITICAL PERF RISK: Sync is O(n2). Re-writing disk for every item is too slow.');
      }
    });
  });
}
