import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';
import '../mocks.dart';

void main() {
  group('NetworkClient Unit Tests', () {
    late MockDio mockDio;
    late NetworkClient client;

    setUp(() {
      mockDio = MockDio();
      // Setup default transformer mock for NetworkClient constructor
      when(() => mockDio.transformer).thenReturn(DefaultTransformer());
      when(() => mockDio.interceptors).thenReturn(Interceptors());
      
      client = NetworkClient(
        baseUrl: 'https://test.com',
        dio: mockDio,
      );
    });

    test('Mock a 200 OK response. Verify it returns Success', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: {'id': 1},
        statusCode: 200,
      );

      when(() => mockDio.request(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => response);

      final result = await client.request<Map>(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Success>());
      expect((result as Success).data['id'], 1);
    });

    test('Mock a 500 Server Error. Verify it returns Failure', () async {
      when(() => mockDio.request(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      ));

      final result = await client.request(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).statusCode, 500);
    });

    test('Mock a connectionTimeout. Verify it returns Failure message', () async {
      when(() => mockDio.request(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await client.request(
        path: '/test',
        method: HttpMethod.get,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).message, contains('Connection timed out'));
    });
  });
}
