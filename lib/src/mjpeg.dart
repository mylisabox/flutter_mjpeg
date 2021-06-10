import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _MjpegStateNotifier extends ChangeNotifier {
  bool _mounted = true;
  bool _visible = true;

  _MjpegStateNotifier() : super();

  bool get mounted => _mounted;

  bool get visible => _visible;

  set visible(value) {
    _visible = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _mounted = false;
    notifyListeners();
    super.dispose();
  }
}

/// A Mjpeg.
class Mjpeg extends HookWidget {
  final String stream;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool isLive;
  final Duration timeout;
  final WidgetBuilder? loading;
  final Widget Function(BuildContext contet, dynamic error, dynamic stack)? error;
  final Map<String, String> headers;

  const Mjpeg({
    this.isLive = false,
    this.width,
    this.timeout = const Duration(seconds: 5),
    this.height,
    this.fit,
    required this.stream,
    this.error,
    this.loading,
    this.headers = const {},
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final image = useState<MemoryImage?>(null);
    final state = useMemoized(() => _MjpegStateNotifier());
    final visible = useListenable(state);
    final errorState = useState<List<dynamic>?>(null);
    final manager = useMemoized(() => _StreamManager(stream, isLive && visible.visible, headers, timeout), [stream, isLive, visible.visible, timeout]);
    final key = useMemoized(() => UniqueKey(), [manager]);

    useEffect(() {
      errorState.value = null;
      manager.updateStream(context, image, errorState);
      return manager.dispose;
    }, [manager]);

    if (errorState.value != null) {
      return SizedBox(
        width: width,
        height: height,
        child: error == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${errorState.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            : error!(context, errorState.value!.first, errorState.value!.last),
      );
    }

    if (image.value == null) {
      return SizedBox(width: width, height: height, child: loading == null ? Center(child: CircularProgressIndicator()) : loading!(context));
    }

    return VisibilityDetector(
      key: key,
      child: Image(
        image: image.value!,
        width: width,
        height: height,
        gaplessPlayback: true,
        fit: fit,
      ),
      onVisibilityChanged: (VisibilityInfo info) {
        if (visible.mounted) {
          visible.visible = info.visibleFraction != 0;
        }
      },
    );
  }
}

class _StreamManager {
  static const _trigger = 0xFF;
  static const _soi = 0xD8;
  static const _eoi = 0xD9;

  final String stream;
  final bool isLive;
  final Duration _timeout;
  final Map<String, String> headers;
  final Client _httpClient = Client();
  // ignore: cancel_subscriptions
  StreamSubscription? _subscription;

  _StreamManager(this.stream, this.isLive, this.headers, this._timeout);

  Future<void> dispose() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    _httpClient.close();
  }

  void _sendImage(BuildContext context, ValueNotifier<MemoryImage?> image, ValueNotifier<dynamic> errorState, List<int> chunks) async {
    final imageMemory = MemoryImage(Uint8List.fromList(chunks));
    errorState.value = null;
    image.value = imageMemory;
  }

  void updateStream(BuildContext context, ValueNotifier<MemoryImage?> image, ValueNotifier<List<dynamic>?> errorState) async {
    try {
      final request = Request("GET", Uri.parse(stream));
      request.headers.addAll(headers);
      final response = await _httpClient.send(request).timeout(_timeout); //timeout is to prevent process to hang forever in some case

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var _carry = <int>[];
        _subscription = response.stream.listen((chunk) async {
          if (_carry.isNotEmpty && _carry.last == _trigger) {
            if (chunk.first == _eoi) {
              _carry.add(chunk.first);
              _sendImage(context, image, errorState, _carry);
              _carry = [];
              if (!isLive) {
                dispose();
              }
            }
          }

          for (var i = 0; i < chunk.length - 1; i++) {
            final d = chunk[i];
            final d1 = chunk[i + 1];

            if (d == _trigger && d1 == _soi) {
              _carry.add(d);
            } else if (d == _trigger && d1 == _eoi && _carry.isNotEmpty) {
              _carry.add(d);
              _carry.add(d1);

              _sendImage(context, image, errorState, _carry);
              _carry = [];
              if (!isLive) {
                dispose();
              }
            } else if (_carry.isNotEmpty) {
              _carry.add(d);
              if (i == chunk.length - 2) {
                _carry.add(d1);
              }
            }
          }
        }, onError: (error, stack) {
          try {
            errorState.value = [error, stack];
            image.value = null;
          } catch (ex) {}
          dispose();
        }, cancelOnError: true);
      } else {
        errorState.value = [HttpException('Stream returned ${response.statusCode} status'), StackTrace.current];
        image.value = null;
        dispose();
      }
    } catch (error, stack) {
      // we ignore those errors in case play/pause is triggers
      if (!error.toString().contains('Connection closed before full header was received')) {
        errorState.value = [error, stack];
        image.value = null;
      }
    }
  }
}
