import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response<dynamic> {}
class MockConnectivity extends Mock implements Connectivity {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeResponse extends Fake implements Response<dynamic> {}

void registerTestFallbacks() {
  registerFallbackValue(FakeRequestOptions());
  registerFallbackValue(FakeResponse());
}
