// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNetworkClient extends Mock implements NetworkClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Network Kit Stress & Complexity Tests', () {
    registerTestFallbacks();
    late OfflineStorage storage;
    late MockNetworkClient mockClient;
    late SyncManager syncManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = OfflineStorage();
      mockClient = MockNetworkClient();
      syncManager = SyncManager(mockClient, storage: storage);
    });

    test('Stress Test: Queuing 1,000 requests', () async {
      final watch = Stopwatch()..start();
      
      final payload = {
        'id': 'test-uuid-001',
        'data': 'A' * 400,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final jsonPayload = jsonEncode({
        'path': '/api/test',
        'method': 'post',
        'data': payload,
      });

      print('--- Memory Stress Test ---');
      for (int i = 0; i < 1000; i++) {
        await storage.saveRequest(jsonPayload);
      }
      
      final queue = await storage.getQueue();
      watch.stop();

      print('Time to queue 1,000 requests: ${watch.elapsedMilliseconds}ms');
      print('Final queue size: ${queue.length}');
      
      // confirm the 200-item cap is working
      expect(queue.length, 200);
    });

    test('Stress Test: Parsing large JSON (5MB)', () async {
      print('\n--- CPU Stress Test ---');
      final buffer = StringBuffer('{ "data": [');
      for (int i = 0; i < 50000; i++) {
        buffer.write('{ "id": $i, "value": "some test data" }');
        if (i < 49999) buffer.write(',');
      }
      buffer.write('] }');
      final rawJson = buffer.toString();
      
      print('Payload size: ${rawJson.length / (1024 * 1024)} MB');

      final watch = Stopwatch()..start();
      final decoded = jsonDecode(rawJson);
      watch.stop();

      print('Main thread decoding time: ${watch.elapsedMilliseconds}ms');
      
      if (watch.elapsedMilliseconds > 16) {
        print('⚠️ Warning: Large JSON decode blocks UI thread (> 16ms).');
      }
      
      expect(decoded, isA<Map<dynamic, dynamic>>());
    });

    test('Throughput Test: Syncing capped queue', () async {
      print('\n--- Throughput Stress Test ---');
      
      final jsonPayload = jsonEncode({
        'path': '/api/test',
        'method': 'post',
        'data': {'test': 'data'},
      });
      for (int i = 0; i < 1000; i++) {
        await storage.saveRequest(jsonPayload);
      }

      when(() => mockClient.request<dynamic>(
        path: any(named: 'path'),
        method: any(named: 'method'),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
      )).thenAnswer((_) async => const Success<dynamic>({'status': 'ok'}));

      final watch = Stopwatch()..start();
      await syncManager.startSync();
      watch.stop();

      print('Sync time for 200 items: ${watch.elapsedMilliseconds}ms');
      print('Avg time per item: ${watch.elapsedMilliseconds / 200}ms');
      
      final queue = await storage.getQueue();
      expect(queue.length, 0);

      if (watch.elapsedMilliseconds > 1000) {
        print('⚠️ Warning: Sync performance is degrading.');
      }
    });
  });
}
