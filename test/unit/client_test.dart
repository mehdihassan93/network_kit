import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import '../mocks.dart';

void main() {
  group('NetworkClient Unit Tests', () {
    registerTestFallbacks();
    late MockDio mockDio;
    late NetworkClient client;

    setUp(() {
      mockDio = MockDio();
      // mock the transformer and interceptors for the constructor
      when(() => mockDio.transformer).thenReturn(BackgroundTransformer());
      when(() => mockDio.interceptors).thenReturn(Interceptors());
      
      client = NetworkClient(
        baseUrl: 'https://test.com',
        dio: mockDio,
      );
    });

    test('should return Success when server returns 200 OK', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        data: {'id': 1},
        statusCode: 200,
      );

      when(() => mockDio.request<dynamic>(
        any<String>(),
        data: any<dynamic>(named: 'data'),
        queryParameters: any<Map<String, dynamic>?>(named: 'queryParameters'),
        cancelToken: any<CancelToken?>(named: 'cancelToken'),
        options: any<Options?>(named: 'options'),
      )).thenAnswer((_) async => response);

      final result = await client.request<Map<dynamic, dynamic>>(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Success<Map<dynamic, dynamic>>>());
      expect((result as Success<Map<dynamic, dynamic>>).data['id'], 1);
    });

    test('should return Failure when server returns 500 Error', () async {
      when(() => mockDio.request<dynamic>(
        any<String>(),
        data: any<dynamic>(named: 'data'),
        queryParameters: any<Map<String, dynamic>?>(named: 'queryParameters'),
        cancelToken: any<CancelToken?>(named: 'cancelToken'),
        options: any<Options?>(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      ));

      final result = await client.request<dynamic>(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure<dynamic>).statusCode, 500);
    });

    test('should return Failure message on connection timeout', () async {
      when(() => mockDio.request<dynamic>(
        any<String>(),
        data: any<dynamic>(named: 'data'),
        queryParameters: any<Map<String, dynamic>?>(named: 'queryParameters'),
        cancelToken: any<CancelToken?>(named: 'cancelToken'),
        options: any<Options?>(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await client.request<dynamic>(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure<dynamic>).message, contains('Connection timed out'));
    });
  });
}
