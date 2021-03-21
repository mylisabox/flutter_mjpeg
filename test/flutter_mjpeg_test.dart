import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

const _trigger = 0xFF;
const _soi = 0xD8;
const _eoi = 0xD9;

void main() {
  final streamController = StreamController<List<int>>.broadcast();

  streamController.stream.transform(JpegSplitter()).listen((data) {
    print(data[0]);
    print(data[1]);
    print(data[data.length - 1]);
    print(data[data.length - 2]);
  });

  //streamController.add([_trigger, _soi, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, _trigger, _eoi]);
  streamController.add([23, 23, _trigger, _soi, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, _trigger]);
  streamController.add([_eoi]);

  test('adds one to input values', () {});
}

/// A [StreamTransformer] that splits a [List<int>] into individual mjpeg frame.
///
/// A line is terminated by either a CR (U+000D), a LF (U+000A), a
/// CR+LF sequence (DOS line ending),
/// and a final non-empty line can be ended by the end of the string.
///
/// The returned lines do not contain the line terminators.
class JpegSplitter extends StreamTransformerBase<List<int>, List<int>> {
  const JpegSplitter();

  ChunkedConversionSink<List<int>> startChunkedConversion(Sink<List<int>> sink) {
    return _JpegSplitterSink(sink as ChunkedConversionSink<List<int>?>);
  }

  Stream<List<int>> bind(Stream<List<int>> stream) {
    return Stream<List<int>>.eventTransformed(stream, (EventSink<List<int>> sink) {
      return _JpegSplitterEventSink(sink);
    });
  }
}

class _JpegSplitterSink extends ChunkedConversionSink<List<int>> {
  final ChunkedConversionSink<List<int>?> _sink;

  /// The carry-over from the previous chunk.
  ///
  /// If the previous slice ended in a line without a line terminator,
  /// then the next slice may continue the line.
  List<int>? _carry = [];

  _JpegSplitterSink(this._sink);

  void close() {
    print('close');
    if (_carry != null) {
      _sink.add(_carry);
      _carry = null;
    }
    _sink.close();
  }

  @override
  void add(List<int> chunk) {
    if (_carry!.isNotEmpty && _carry!.last == _trigger) {
      if (chunk.first == _eoi) {
        _carry!.add(chunk.first);
        _sink.add(_carry);
        _carry = [];
      }
    }

    for (var i = 0; i < chunk.length - 1; i++) {
      final d = chunk[i];
      final d1 = chunk[i + 1];

      if (d == _trigger && d1 == _soi) {
        _carry!.add(d);
      } else if (d == _trigger && d1 == _eoi) {
        _carry!.add(d);
        _carry!.add(d1);
        _sink.add(_carry);
        _carry = [];
      } else if (_carry!.isNotEmpty) {
        _carry!.add(d);
        if (i == chunk.length - 2) {
          _carry!.add(d1);
        }
      }
    }
  }
}

class _JpegSplitterEventSink extends _JpegSplitterSink implements EventSink<List<int>> {
  final EventSink<List<int>> _eventSink;

  _JpegSplitterEventSink(EventSink<List<int>> eventSink)
      : _eventSink = eventSink,
        super(ChunkedConversionSink<List<int>>.withCallback((accumulated) {
          print('accumulated');
        }));

  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
