import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A Mjpeg.
class Mjpeg extends HookWidget {
  final String stream;
  final BoxFit fit;
  final double width;
  final double height;
  final bool isLive;
  final WidgetBuilder loading;
  final Widget Function(BuildContext contet, dynamic error) error;

  Mjpeg({
    this.isLive = false,
    this.width,
    this.height,
    this.fit,
    this.stream,
    this.error,
    this.loading,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final image = useState<MemoryImage>(null);
    final errorState = useState<dynamic>(null);
    final manager = useMemoized(() => _StreamManager(stream, isLive), [stream, isLive]);

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

    return Image(
      image: image.value,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

class _StreamManager {
  static const _trigger = 0xFF;
  static const _soi = 0xD8;
  static const _eoi = 0xD9;

  final String stream;
  final bool isLive;
  StreamSubscription _subscription;

  _StreamManager(this.stream, this.isLive);

  Future<void> dispose() {
    if (_subscription != null) {
      return _subscription.cancel();
    }
    return Future.value(null);
  }

  void updateStream(BuildContext context, ValueNotifier<MemoryImage> image, ValueNotifier<dynamic> errorState) async {
    if (stream == null) return;

    try {
      final request = await HttpClient().getUrl(Uri.parse(stream));
      final HttpClientResponse chunk = await request.close();
      var chunks = <int>[];
      _subscription = chunk.listen((data) async {
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
              _subscription.cancel();
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
