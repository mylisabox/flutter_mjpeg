import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:http/http.dart';

/// A Mjpeg.
class Mjpeg extends HookWidget {
  final String stream;
  final BoxFit fit;
  final double width;
  final double height;
  final bool isLive;
  final WidgetBuilder loading;
  final Widget Function(BuildContext contet, dynamic error) error;
  final Map<String, String> headers;

  Mjpeg({
    this.isLive = false,
    this.width,
    this.height,
    this.fit,
    this.stream,
    this.error,
    this.loading,
    this.headers,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final image = useState<MemoryImage>(null);
    final visible = useState<bool>(true);
    final errorState = useState<dynamic>(null);
    final manager = useMemoized(() => _StreamManager(stream, isLive && visible.value, headers), [stream, isLive, visible.value]);
    final key = useMemoized(() => UniqueKey(), [manager]);

    useEffect(() {
      manager.updateStream(context, image, errorState);
      return manager.dispose;
    }, [manager]);

    if (errorState.value != null) {
      return Container(
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
            : error(context, errorState.value),
      );
    }

    if (image.value == null) {
      return Container(width: width, height: height, child: loading == null ? Center(child: CircularProgressIndicator()) : loading(context));
    }

    return VisibilityDetector(
      key: key,
      child: Image(
        image: image.value,
        width: width,
        height: height,
        fit: fit,
      ),
      onVisibilityChanged: (VisibilityInfo info) {
        visible.value = info.visibleFraction != 0;
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
  final Map<String, String> headers;
  final Client _httpClient = Client();
  StreamSubscription _subscription;

  _StreamManager(this.stream, this.isLive, this.headers);

  Future<void> dispose() async {
    _httpClient.close();
    if (_subscription != null) {
      await _subscription.cancel();
      _subscription = null;
    }
  }

  void updateStream(BuildContext context, ValueNotifier<MemoryImage> image, ValueNotifier<dynamic> errorState) async {
    if (stream == null) return;
    try {
      final request = Request("GET", Uri.parse(stream));
      request.headers.addAll(headers ?? Map<String, String>());
      final response = await _httpClient.send(request);
      var chunks = <int>[];
      _subscription = response.stream.listen((data) async {
        if (chunks.isEmpty) {
          final startIndex = data.indexOf(_trigger);
          if (startIndex >= 0 && startIndex + 1 < data.length && data[startIndex + 1] == _soi) {
            final slicedData = data.sublist(startIndex, data.length);
            chunks.addAll(slicedData);
          }
        } else {
          final startIndex = data.lastIndexOf(_trigger);
          if (startIndex + 1 < data.length && data[startIndex + 1] == _eoi) {
            final slicedData = data.sublist(0, startIndex + 2);
            chunks.addAll(slicedData);
            final imageMemory = MemoryImage(Uint8List.fromList(chunks));
            await precacheImage(imageMemory, context);
            errorState.value = null;
            image.value = imageMemory;
            chunks = <int>[];
            if (!isLive) {
              dispose();
            }
          } else {
            chunks.addAll(data);
          }
        }
      });
    } catch (error) {
      errorState.value = error;
      image.value = null;
    }
  }
}
