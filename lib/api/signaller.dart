import 'dart:io';

import 'package:slowbro/api/types.dart';
import 'package:slowbro/utils/id.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

List<GeneralResponse> _parseMessage(dynamic data) {
  String msg = data as String;
  return generalResponseFromJson(msg);
}

List<SignalMessage> _parseSignalMessage(dynamic data) {
  String msg = data as String;
  return signalMessageFromJson(msg);
}

class HandshakeApi {
  final Client _client = Client();

  HandshakeApi();

  Future<HandshakeResponse> handshake(HandshakeRequest request) async {
    HandshakeResponse data = await _client
        .post(Uri.parse("https://rocky-gorge-69260.herokuapp.com"),
        headers: {"Content-Type": "application/json"},
    body: handshakeRequestToJson([request]))
        .then((response) {
      if (response.statusCode != 200) {
        throw "[${response.statusCode}]: ${response.body}";
      }
      return handshakeResponseFromJson(response.body)[0];
    });
    return data;
  }
}


class Signaller {
  int _messagesCounter = 0;
  IOWebSocketChannel? _channel;
  String clientId = getRandomString(31);
  WebSocket? _ws;
  HandshakeApi _handshakeApi = HandshakeApi();
  Stream<dynamic>? _stream;
  bool _handshakeDone = false;
  bool _isReconnecting = false;

  get messageId => "d:${++_messagesCounter}";

  Future<bool> ensureConnected() async {
    bool isConnect = false;
    if (!_handshakeDone) {
      await handshake();
    }
    if (_ws == null) {
      await connect();
      isConnect = true;
    } else {
      while (_isReconnecting) {
        isConnect = true;
        sleep(Duration(milliseconds: 150));
      }
      if (_ws == null || _ws!.readyState != 1) throw "cannot ensure signaller connection";
    }
    return isConnect;
  }

  Future<void> handshake() async {
    print("Doing Faye handshake...");
    final response = await _handshakeApi.handshake(HandshakeRequest(channel: "/meta/handshake", version: "1.0", supportedConnectionTypes: ["websocket","eventsource","long-polling","cross-origin-long-polling","callback-polling"], id: messageId));
    if (!response.successful) throw "unsuccessful handshake";
    clientId = response.clientId;
    print("Faye handshake ready! Client ID: $clientId");
    _handshakeDone = true;
  }

  Future<void> connect() async {
    try {
      print("Connecting to WS...");
      _ws = await WebSocket.connect('wss://rocky-gorge-69260.herokuapp.com');
      print("WS ready...");
      _ws!.done.then((_) => _onDisconnect());
      _channel = IOWebSocketChannel(_ws!);

      String connectRequest = connectRequestToJson([ConnectRequest(channel: "/meta/connect", clientId: clientId, connectionType: "websocket", id: "$messageId")]);
      print(connectRequest);
      if (_channel == null) {
        throw "WS channel is null";
      }
      _channel!.sink.add(connectRequest);
      print("Success. Connected to signaller!");
    } catch (e) {
      print(e);
      throw e;
    }
  }

  _onDisconnect() async {
    _isReconnecting = true;
    print("Signaller disconnected. Reconnecting in 300ms...");
    sleep(Duration(milliseconds: 300));
    try {
      await connect();
    } catch (e) {
      print(e);
      throw e;
    } finally {
      _isReconnecting = false;
    }
  }

  close() {
    if (_ws == null) return;
    _ws?.close();
    _channel?.sink.close(status.goingAway);
  }

  Future<SignallerTopic> getTopic(String id) async {
    if (_channel == null) {
      throw "WS channel is null";
    }
    String msgID = messageId;
    print("Connecting to topic $id...");
    final _s = _channel?.stream.asBroadcastStream();
    sink!.add(subscribeRequestToJson([SubscribeRequest(channel: "/meta/subscribe", clientId: clientId, subscription: id, id: msgID)]));
    await _s!.map(_parseMessage).firstWhere((data) =>
       data.any((msg) => msg.id == msgID && msg.clientId == clientId && msg.channel == "/meta/subscribe"));
    print("Success. Connected to topic $id!");
    _stream = _s.map((v) {
      print(v);
      return v;
    }).asBroadcastStream();
    return SignallerTopic(this, id, clientId);
  }
  Stream<dynamic>? get stream => _stream;
  Sink<dynamic>? get sink => _channel?.sink;

}

class SignallerTopic {
  final Signaller _signaller;
  final String id;
  final String _clientId;

  const SignallerTopic(this._signaller, this.id, this._clientId);
  
  Stream<SignalMessage>? get stream => _signaller.stream!.where((events){
    final parsedEvents = _parseMessage(events);
    return parsedEvents.any((element) => element.channel == id);
  }).map(_parseSignalMessage).expand((element) => element);
  Sink<dynamic>? get sink => _signaller.sink;


  String sendSignal(String data) {
    final m = SignalMessage(channel: id, data: data, clientId: _clientId, id: _signaller.messageId);
    String msg = signalMessageToJson([m]);
    sink!.add(msg);
    return m.id!;
  }

  Future<String> sendAndAwaitResponse(String data, bool Function(String) matcher) async {
    sendSignal(data);
    SignalMessage msg = await stream!.firstWhere((element) => element.data == null ? false : matcher(element.data!));
    return msg.data!;
  }

  Future<void> unsubscribe() async {
    String msgID = _signaller.messageId;
    print("Disconnecting topic $id...");
    sink!.add(subscribeRequestToJson([SubscribeRequest(channel: "/meta/unsubscribe", clientId: _clientId, subscription: id, id: msgID)]));
    await stream!.map(_parseMessage).firstWhere((data) =>
        data.any((msg) => msg.id == msgID && msg.clientId == _clientId && msg.channel == "/meta/unsubscribe"));
    print("Success. Disconnected from topic $id!");
  }
}
