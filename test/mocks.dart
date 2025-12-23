import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_kit/network_kit.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response<dynamic> {}
class MockConnectivity extends Mock implements Connectivity {}
class MockAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeOptions extends Fake implements Options {}
class FakeResponse extends Fake implements Response<dynamic> {}
class FakeCancelToken extends Fake implements CancelToken {}

void registerTestFallbacks() {
  try {
    registerFallbackValue(HttpMethod.get);
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeCancelToken());
  } catch (_) {}
}
