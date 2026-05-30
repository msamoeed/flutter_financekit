import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_financekit/flutter_financekit.dart';
import 'package:flutter_financekit/flutter_financekit_platform_interface.dart';
import 'package:flutter_financekit/flutter_financekit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterFinancekitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterFinancekitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterFinancekitPlatform initialPlatform = FlutterFinancekitPlatform.instance;

  test('$MethodChannelFlutterFinancekit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterFinancekit>());
  });

  test('getPlatformVersion', () async {
    FlutterFinancekit flutterFinancekitPlugin = FlutterFinancekit();
    MockFlutterFinancekitPlatform fakePlatform = MockFlutterFinancekitPlatform();
    FlutterFinancekitPlatform.instance = fakePlatform;

    expect(await flutterFinancekitPlugin.getPlatformVersion(), '42');
  });
}
