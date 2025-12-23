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
      
      when(() => mockDio.transformer).thenReturn(BackgroundTransformer());
      final interceptors = Interceptors();
      when(() => mockDio.interceptors).thenReturn(interceptors);

      client = NetworkClient(
        baseUrl: 'https://test.com',
        dio: mockDio,
        storage: storage,
      );

      syncManager = SyncManager(client, storage: storage);
    });

    test('Full sync loop: capture offline request and replay once back online', () async {
      // 1. Force a connection error to trigger queuing.
      when(() => mockDio.request<dynamic>(
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

      // 4. Mock server recovery for the replay attempt.
      when(() => mockDio.request<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/post'),
            statusCode: 200,
            data: {'id': 1},
          ));

      // 5. Run the synchronization process.
      await syncManager.startSync();

      // 6. Confirm the queue is flushed.
      final finalQueue = await storage.getQueue();
      expect(finalQueue.isEmpty, true);
    });
  });
}
