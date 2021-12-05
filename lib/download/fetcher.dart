import 'dart:io';
import 'dart:typed_data';

import 'package:slowbro/api/event_types.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:async/async.dart';

import 'dart:async';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

class Fragment {
  final int id;
  final Uint8List data;
  final double offset;
  final double duration;
  int downloaded = 0;
  double? keep;

  Fragment({required this.id, required this.data, required this.offset, required this.duration, this.keep});
}

class Fetcher {
  final PeerProvider provider;
  List<Fragment> fragments = [];
  int? lastID;
  double? lastKeep;
  StreamController<Uint8List> _end = StreamController.broadcast();

  Fetcher(this.provider);

  Future<List<String>> writeFragmentsToFiles() async {
    final int t = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    Directory tempDir = await getTemporaryDirectory();
    return Future.wait(fragments.map((f) async {
      final path = '${tempDir.path}/${t}_${f.id}.ts';
      final v = new File(path);
      await v.writeAsBytes(f.data);
      return path;
    }));
  }

  Stream<int> download(double firstOffset,  double duration, int length) {
    fragments = [new Fragment(id: 0, data: new Uint8List(length), offset: firstOffset, duration: duration)];
    lastID = null;
    return StreamGroup.merge<Uint8List>([provider.binaryMessages, _end.stream]).map((bytes) {
      if (bytes.length == 0) return 0;
      return decodeChunk(bytes);
    }).takeWhile((bytesWritten) {
      return lastID == null || fragments.any((f) => f.data.length != f.downloaded);
    }).map((bytesWritten) {
      return bytesWritten;
    });
  }

  void stopDownload(int lastID, double keep, int lastLength, double lastDuration) {
    this.lastID = lastID;
    lastKeep = keep;
    final lastFragmentIdx = fragments.indexWhere((f) => f.id == lastID);
    final f = lastFragmentIdx == -1 ?
      Fragment(id: lastID, data: new Uint8List(lastLength), offset: 0, duration: lastDuration) :
      fragments[lastFragmentIdx];
    f.keep = keep;
    if (lastFragmentIdx == -1) {
      fragments.add(f);
    }
    _end.sink.add(new Uint8List(0));
  }

  void destroy() {
    _end.close();
  }

  int decodeChunk (Uint8List source) {
    // event_type(uint16)|id(uint16)|from(uint32)|to(uint32)|total(uint32)|duration(float32)|payload(uint8list)
    const headerLength = Uint16List.bytesPerElement * 2 + Uint32List.bytesPerElement * 3 + Float32List.bytesPerElement;
    final v = source.buffer.asByteData(source.offsetInBytes, headerLength);

    final eventType = v.getUint16(0, Endian.little);
    if (eventType != EVENT_TYPE_SHARE_MEDIA_DATA) {
      return 0;
    }
    int id = v.getUint16(Uint16List.bytesPerElement, Endian.little);
    int from = v.getUint32(Uint16List.bytesPerElement * 2, Endian.little);
    int to = v.getUint32(Uint16List.bytesPerElement * 2 + Uint32List.bytesPerElement, Endian.little);
    int total = v.getUint32(Uint16List.bytesPerElement * 2 + Uint32List.bytesPerElement * 2, Endian.little);
    double duration = v.getFloat32(Uint16List.bytesPerElement * 2 + Uint32List.bytesPerElement * 3, Endian.little);
    final chunk = source.sublist(headerLength);
    final fragmentIdx = fragments.indexWhere((f) => f.id == id);
    final f = fragmentIdx == -1 ?
      Fragment(id: id, data: new Uint8List(total), offset: 0, duration: duration) :
        fragments[fragmentIdx];
    f.downloaded += chunk.length;
    f.data.setAll(from, chunk);
    if (fragmentIdx == -1) {
      fragments.add(f);
    }
    return chunk.length;
  }
}

