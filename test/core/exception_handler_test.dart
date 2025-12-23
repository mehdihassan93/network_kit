import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_kit/src/core/exception_handler.dart';
import 'package:network_kit/src/models/network_result.dart';

void main() {
  group('ExceptionHandler Unit Tests', () {
    test('should return Failure with "Connection timed out" on connectionTimeout', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      );

      final result = ExceptionHandler.handleException(dioError);

      expect(result, isA<Failure>());
      expect((result as Failure).message, 'Connection timed out');
    });

    test('should extract message from server response on badResponse', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'message': 'Invalid credentials'},
        ),
      );

      final result = ExceptionHandler.handleException(dioError);

      expect(result, isA<Failure>());
      final failure = result as Failure;
      expect(failure.message, 'Invalid credentials');
      expect(failure.statusCode, 400);
    });

    test('should return "Unexpected Error" for non-Dio errors', () {
      final error = Exception('Some random error');

      final result = ExceptionHandler.handleException(error);

      expect(result, isA<Failure>());
      expect((result as Failure).message, 'Unexpected Error');
    });
  });
}
