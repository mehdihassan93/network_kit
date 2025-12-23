import 'package:flutter_test/flutter_test.dart';
import 'package:network_kit/src/internal/offline_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineStorage Unit Tests', () {
    late OfflineStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = OfflineStorage();
    });

    test('Save Request -> Verify it writes to SharedPreferences', () async {
      const json = '{"path": "/test"}';
      await storage.saveRequest(json);
      
      final queue = await storage.getQueue();
      expect(queue, contains(json));
    });

    test('Queue Cap -> Save 205 requests. Verify length is exactly 200', () async {
      for (int i = 0; i < 205; i++) {
        await storage.saveRequest('{"id": $i}');
      }
      
      final queue = await storage.getQueue();
      expect(queue.length, 200);
      // Verify FIFO: oldest (0-4) are dropped, 5 is the first
      expect(queue.first, '{"id": 5}');
      expect(queue.last, '{"id": 204}');
    });

    test('FIFO Order -> Verify first in is first out', () async {
      await storage.saveRequest('{"id": 1}');
      await storage.saveRequest('{"id": 2}');
      
      final queue = await storage.getQueue();
      expect(queue[0], '{"id": 1}');
      expect(queue[1], '{"id": 2}');
    });
  });
}
