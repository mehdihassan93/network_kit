import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerTestFallbacks();
  });

  group('Sync Integration Tests', () {
    late OfflineStorage storage;
    late MockAdapter mockAdapter;
    late NetworkClient client;
    late SyncManager syncManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = OfflineStorage();
      mockAdapter = MockAdapter();
      
      final dio = Dio(BaseOptions(baseUrl: 'https://test.com'));
      dio.httpClientAdapter = mockAdapter;

      client = NetworkClient(
        baseUrl: 'https://test.com',
        dio: dio,
        storage: storage,
      );

      syncManager = SyncManager(client, storage: storage);
    });

    test('Full sync loop: capture offline request and replay once back online', () async {
      // 1. Mock the adapter to throw a network error.
      // This triggers the real Dio pipeline, which calls QueueInterceptor.
      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenThrow(const SocketException('No Internet'));

      // 2. Attempt a mutation request.
      final result = await client.request<dynamic>(
        path: '/post',
        method: HttpMethod.post,
        data: {'title': 'hello'},
      );

      // 3. Confirm it was intercepted and queued (status 499).
      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure<dynamic>).statusCode, 499);
      
      final queue = await storage.getQueue();
      expect(queue.length, 1);
      expect(queue.first, contains('/post'));

      // 4. Mock server recovery.
      // We return a successful ResponseBody from the adapter.
      final responsePayload = jsonEncode({'id': 1}).codeUnits;
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromBytes(
          Uint8List.fromList(responsePayload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      // 5. Run the synchronization process.
      await syncManager.startSync();

      // 6. Confirm the queue is flushed.
      final finalQueue = await storage.getQueue();
      expect(finalQueue.isEmpty, true);
    });
  });
}
