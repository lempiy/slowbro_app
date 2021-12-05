import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/download/fetcher.dart';
import 'package:slowbro/download/media_transform.dart';
import 'package:share_plus/share_plus.dart';


class Downloader extends StatefulWidget {
  final PeerProvider provider;
  final void Function() onTouchPressed;
  final Fetcher fetcher;
  final MediaTransformer transformer = new MediaTransformer();
  final ConfigPayload pointerOptions;
  final IconData? toggleIcon;

  Downloader({Key? key, required this.provider, required this.onTouchPressed, required this.pointerOptions, this.toggleIcon}) :
        this.fetcher = new Fetcher(provider),
        super(key: key);

  @override
  State<Downloader> createState() => _DownloaderState();
}

class _DownloaderState extends State<Downloader> with SingleTickerProviderStateMixin {
  bool capturing = false;
  bool downloading = false;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  bool transcoding = false;
  int? _bts;

  @override
  void initState() {
    _ticker = this.createTicker((elapsed) {
      _elapsed = elapsed;

      if (_elapsed >= Duration(seconds: 10)) onEndDownload();
      setState(() {});
    });
    super.initState();
  }


  onStartDownload() async {
    print("Start DIWLOAD");
    _bts = 0;
    final event = jsonEncode({"type": "share-request", "payload": {"timestamp": DateTime.now().millisecondsSinceEpoch}});
    print("Start ");
    widget.provider.sendTextMessage(event);
    final approve = await widget.provider.textMessages.map((text) => shareRequestAnswerFromJson(text)).firstWhere((event) => event.type == "share-request-reply");
    if (!approve.payload.ok) {
      print("non ok approve ${approve.payload.reason}");
      return;
    }
    _ticker.start();
    print(approve);
    download(approve.payload.offset, approve.payload.duration, approve.payload.length);
    setState(() {
      capturing = true;
      downloading = true;
    });
  }

  onTransformed(List<String> paths) async {
    setState(() {
      transcoding = false;
    });
    await Share.shareFiles(paths);
  }

  onError(e) async {
    print(e);
  }

  download(double startOffset, double duration, int length) async {
    final int totalDownloaded = await widget.fetcher.download(startOffset, duration, length).
    map((chunk) {
      _bts = _bts ?? 0;
      _bts = _bts! + chunk;
      setState(() {});
      return chunk;
    }).
    reduce((total, loaded) => total+loaded);
    widget.fetcher.fragments.forEach((f) {
      print("ts: ${f.id}, duration: ${f.duration}, from: ${f.offset}, keep: ${f.keep}");
    });
    print("total downloaded ${widget.fetcher.fragments.length} $totalDownloaded bytes.");
    setState(() {
      transcoding = true;
    });
    final files = await widget.fetcher.writeFragmentsToFiles();
    print(files);
    try {
      await widget.transformer.concat(List.generate(files.length,
              (i) => i).map((i) =>
          ConcatPart(files[i],
            from: widget.fetcher.fragments[i].offset == 0.0 ? null : widget
                .fetcher.fragments[i].offset,
            take: widget.fetcher.fragments[i].keep),

      ).toList(), (String str) => onTransformed([str]));
    } catch (e) {
      onError(e);
    }
  }

  onEndDownload() async {
    print("end dowload");
    if (!capturing) return;
    final event = jsonEncode({"type": "share-request-stop", "payload": {"timestamp": DateTime.now().millisecondsSinceEpoch}});
    widget.provider.sendTextMessage(event);
    _ticker.stop();
    capturing = false;
    final approve = await widget.provider.textMessages.map((text) => shareRequestStopAnswerFromJson(text)).firstWhere((event) => event.type == "share-request-stop-reply");
    if (!approve.payload.ok) {
      print("non ok stop approve ${approve.payload.reason}");
      return;
    }
    widget.fetcher.stopDownload(approve.payload.keepID, approve.payload.keep,
        approve.payload.keepFullLength, approve.payload.keepFullDuration);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                widget.toggleIcon,
                size: 30,
              ),
              onPressed: widget.onTouchPressed,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: GestureDetector(
            child: Container(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: _ticker.isTicking ? CircularProgressIndicator(
                        color: Colors.teal,
                        strokeWidth: 6,
                        value: _elapsed.inMilliseconds / 10000
                    ) : Container(),
                  ),
                  Center(child: transcoding ? SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: Colors.teal)) : ElevatedButton(
                    onPressed: (){},
                    child: Icon(Icons.camera, size: 60, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      primary: capturing ? Colors.tealAccent : Colors.teal, // <-- Button color
                      onPrimary: Colors.tealAccent, // <-- Splash color
                    ),))
                ],
              ),
            ),
            onLongPressStart: (details) {
              onStartDownload();
            },
            onLongPressEnd: (details) {
              onEndDownload();
            },
          ),
        ),
      ),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: _bts != null ? Container(
              child: Text(
                "${MediaTransformer.formatBytes(_bts!, 1)}",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 60,
                ),
              ),
            ) : Container(),
          ),
        ),
      ]
    );
  }
}