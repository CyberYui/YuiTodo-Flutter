import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/notifications/sound_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    calls.clear();
    messenger.setMockMethodCallHandler(SoundPreview.channel, (call) async {
      calls.add(call);
      return true;
    });
    await SoundPreview.instance.stop();
    calls.clear();
  });

  tearDown(() async {
    await SoundPreview.instance.stop();
    messenger.setMockMethodCallHandler(SoundPreview.channel, null);
  });

  test('switching sounds stops the previous preview before playing', () async {
    await SoundPreview.instance.toggle('chime');
    expect(SoundPreview.instance.isPlaying('chime'), isTrue);
    expect(calls.where((call) => call.method == 'play').length, 1);
    final firstArgs = calls.last.arguments as Map;
    expect(firstArgs['raw'], 'yuitodo_chime');
    final firstToken = firstArgs['token'] as int;

    calls.clear();
    await SoundPreview.instance.toggle('bell');
    expect(SoundPreview.instance.isPlaying('bell'), isTrue);
    expect(SoundPreview.instance.isPlaying('chime'), isFalse);
    expect(calls.first.method, 'stop');
    expect(calls.where((call) => call.method == 'play').length, 1);
    final secondArgs = calls.last.arguments as Map;
    expect(secondArgs['raw'], 'yuitodo_bell');
    expect(secondArgs['token'] as int, greaterThan(firstToken));
  });

  test('tapping the playing sound stops it', () async {
    await SoundPreview.instance.toggle('bell');
    calls.clear();
    await SoundPreview.instance.toggle('bell');
    expect(SoundPreview.instance.playingKey, isNull);
    expect(calls.single.method, 'stop');
  });

  test('stale completion does not clear a newer preview', () async {
    await SoundPreview.instance.toggle('chime');
    final firstToken = (calls.last.arguments as Map)['token'] as int;
    await SoundPreview.instance.toggle('bell');
    final secondToken = (calls.last.arguments as Map)['token'] as int;

    await messenger.handlePlatformMessage(
      'com.yuitodo/sound_preview',
      codec.encodeMethodCall(MethodCall('onComplete', firstToken)),
      (_) {},
    );
    expect(SoundPreview.instance.isPlaying('bell'), isTrue);

    await messenger.handlePlatformMessage(
      'com.yuitodo/sound_preview',
      codec.encodeMethodCall(MethodCall('onComplete', secondToken)),
      (_) {},
    );
    expect(SoundPreview.instance.playingKey, isNull);
  });

  test('system option previews with a null raw name', () async {
    await SoundPreview.instance.toggle(null);
    expect(calls.last.method, 'play');
    final args = calls.last.arguments as Map;
    expect(args['raw'], isNull);
    expect(args['token'], isA<int>());
  });
}
