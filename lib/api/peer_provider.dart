import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:slowbro/api/peer.dart';
import 'package:slowbro/api/signaller.dart';

class PeerProvider {
  final Signaller _signaller;
  final String code;
  bool _destroyed = false;
  SignallerTopic? _topic;
  Peer? _currentPeer;
  StreamSubscription? _sub;
  StreamSubscription? _messageSub;
  StreamController<String> _textMessagesController = StreamController.broadcast();
  StreamController<Uint8List> _binaryMessagesController = StreamController.broadcast();


  PeerProvider(this._signaller, this.code);

  static Future<PeerProvider> create(Signaller signaller, String code) async {
    final provider = PeerProvider(signaller, code);
    await provider.reconnect();
    return provider;
  }

  Stream<String> get textMessages => _textMessagesController.stream.asBroadcastStream();
  Stream<Uint8List> get binaryMessages => _binaryMessagesController.stream.asBroadcastStream();

  Future<void> reconnect() async {
    final isReconnect = await _signaller.ensureConnected();
    if (isReconnect || _topic == null) {
      _topic = await _signaller.getTopic("/$code");
    }
    if (_currentPeer != null) {
      _currentPeer!.destroy();
    }
    _currentPeer = Peer(_signaller.clientId , _topic!, onClose: _onClosedChannel);
    await _currentPeer!.prepare();
    await _currentPeer!.offer();
    print("waiting online status...");
    bool? done = await Future.any([_currentPeer!.onlineStatus.firstWhere((ok) => ok), Future.delayed(Duration(seconds: 3))]);
    if (done == null || !done) {
      print("Peer timeout on connect. reconnecting...");
      sleep(Duration(milliseconds: 300));
      return reconnect();
    }
    print("Now online!");
    _sub = _currentPeer!.onlineStatus.listen((isOnline) {
      if (!isOnline) {
        _sub?.cancel();
        _messageSub?.cancel();
        reconnect();
      }
    });
    _messageSub = _currentPeer!.messages.listen((event) {
      if (event.isBinary) {
        _binaryMessagesController.sink.add(event.binary);
      } else {
        _textMessagesController.sink.add(event.text);
      }
    });
  }

  void _onClosedChannel() {
    if (_destroyed) return;
    reconnect();
  }

  void sendTextMessage(String text) {
    if (_currentPeer != null && _currentPeer!.online) {
      _currentPeer!.messageText(text);
    } else {
      print("peer offline. skipping text message...");
    }
  }

  void sendBinaryMessage(Uint8List msg) {
    if (_currentPeer != null && _currentPeer!.online) {
      _currentPeer!.messageBinary(msg);
    } else {
      print("peer offline. skipping binary message...");
    }
  }

  void destroy() {
    if (_currentPeer != null) {
      _currentPeer!.destroy();
      _topic!.unsubscribe();
    }
    _destroyed = true;
    _sub?.cancel();
    _messageSub?.cancel();
    _binaryMessagesController.close();
    _textMessagesController.close();
  }
}
