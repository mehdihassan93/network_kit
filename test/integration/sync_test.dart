import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sync Integration Tests', () {
    late OfflineStorage storage;
    late MockDio mockDio;
    late NetworkClient client;
    late SyncManager syncManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = OfflineStorage();
      mockDio = MockDio();
      
      when(() => mockDio.transformer).thenReturn(DefaultTransformer());
      final interceptors = Interceptors();
      when(() => mockDio.interceptors).thenReturn(interceptors);

      client = NetworkClient(
        baseUrl: 'https://test.com',
        dio: mockDio,
        storage: storage,
      );

      syncManager = SyncManager(client, storage: storage);
    });

    test('Full Loop: Offline -> Request Queue -> Online -> Sync', () async {
      // 1. Simulate Offline State via SocketException
      when(() => mockDio.request(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/post'),
        error: const SocketException('No Internet'),
        type: DioExceptionType.connectionError,
      ));

      // 2. Call request()
      final result = await client.request(
        path: '/post',
        method: HttpMethod.post,
        data: {'title': 'hello'},
      );

      // 3. Verify it returns Status 499 and item is stored
      expect(result, isA<Failure>());
      expect((result as Failure).statusCode, 499);
      
      final queue = await storage.getQueue();
      expect(queue.length, 1);
      expect(queue.first, contains('/post'));

      // 4. Mock Success for Replay
      when(() => mockDio.request(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/post'),
            statusCode: 200,
            data: {'id': 1},
          ));

      // 5. Trigger Sync
      await syncManager.startSync();

      // 6. Verify storage is empty after sync
      final finalQueue = await storage.getQueue();
      expect(finalQueue.isEmpty, true);
    });
  });
}
