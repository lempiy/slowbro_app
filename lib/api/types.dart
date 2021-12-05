// To parse this JSON data, do
//
//     final connectRequest = connectRequestFromJson(jsonString);

import 'dart:convert';

List<ConnectRequest> connectRequestFromJson(String str) => List<ConnectRequest>.from(json.decode(str).map((x) => ConnectRequest.fromJson(x)));

String connectRequestToJson(List<ConnectRequest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ConnectRequest {
  ConnectRequest({
    required this.channel,
    required this.clientId,
    required this.connectionType,
    required this.id,
  });

  String channel;
  String clientId;
  String connectionType;
  String id;

  factory ConnectRequest.fromJson(Map<String, dynamic> json) => ConnectRequest(
    channel: json["channel"],
    clientId: json["clientId"],
    connectionType: json["connectionType"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "channel": channel,
    "clientId": clientId,
    "connectionType": connectionType,
    "id": id,
  };
}

List<SubscribeRequest> subscribeRequestFromJson(String str) => List<SubscribeRequest>.from(json.decode(str).map((x) => SubscribeRequest.fromJson(x)));

String subscribeRequestToJson(List<SubscribeRequest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SubscribeRequest {
  SubscribeRequest({
    this.channel,
    this.clientId,
    this.subscription,
    this.id,
  });

  String? channel;
  String? clientId;
  String? subscription;
  String? id;

  factory SubscribeRequest.fromJson(Map<String, dynamic> json) => SubscribeRequest(
    channel: json["channel"],
    clientId: json["clientId"],
    subscription: json["subscription"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "channel": channel,
    "clientId": clientId,
    "subscription": subscription,
    "id": id,
  };
}

List<SubscribeResponse> subscribeResponseFromJson(String str) => List<SubscribeResponse>.from(json.decode(str).map((x) => SubscribeResponse.fromJson(x)));

String subscribeResponseToJson(List<SubscribeResponse> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SubscribeResponse {
  SubscribeResponse({
    this.id,
    this.clientId,
    this.channel,
    this.successful,
    this.subscription,
  });

  String? id;
  String? clientId;
  String? channel;
  bool? successful;
  String? subscription;

  factory SubscribeResponse.fromJson(Map<String, dynamic> json) => SubscribeResponse(
    id: json["id"],
    clientId: json["clientId"],
    channel: json["channel"],
    successful: json["successful"],
    subscription: json["subscription"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "clientId": clientId,
    "channel": channel,
    "successful": successful,
    "subscription": subscription,
  };
}

List<GeneralResponse> generalResponseFromJson(String str) => List<GeneralResponse>.from(json.decode(str).map((x) => GeneralResponse.fromJson(x)));

String generalResponseToJson(List<GeneralResponse> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GeneralResponse {
  GeneralResponse({
    this.id,
    this.clientId,
    this.channel,
  });

  String? id;
  String? clientId;
  String? channel;

  factory GeneralResponse.fromJson(Map<String, dynamic> json) => GeneralResponse(
    id: json["id"],
    clientId: json["clientId"],
    channel: json["channel"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "clientId": clientId,
    "channel": channel,
  };
}

List<SignalMessage> signalMessageFromJson(String str) => List<SignalMessage>.from(json.decode(str).map((x) => SignalMessage.fromJson(x)));

String signalMessageToJson(List<SignalMessage> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SignalMessage {
  SignalMessage({
    this.channel,
    this.data,
    this.clientId,
    this.id,
  });

  String? channel;
  String? data;
  String? clientId;
  String? id;

  factory SignalMessage.fromJson(Map<String, dynamic> json) => SignalMessage(
    channel: json["channel"],
    data: json["data"],
    clientId: json["clientId"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "channel": channel,
    "data": data,
    "clientId": clientId,
    "id": id,
  };
}

List<HandshakeRequest> handshakeRequestFromJson(String str) => List<HandshakeRequest>.from(json.decode(str).map((x) => HandshakeRequest.fromJson(x)));

String handshakeRequestToJson(List<HandshakeRequest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HandshakeRequest {
  HandshakeRequest({
    required this.channel,
    required this.version,
    required this.supportedConnectionTypes,
    required this.id,
  });

  String channel;
  String version;
  List<String> supportedConnectionTypes;
  String id;

  factory HandshakeRequest.fromJson(Map<String, dynamic> json) => HandshakeRequest(
    channel: json["channel"],
    version: json["version"],
    supportedConnectionTypes: List<String>.from(json["supportedConnectionTypes"].map((x) => x)),
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "channel": channel,
    "version": version,
    "supportedConnectionTypes": List<dynamic>.from(supportedConnectionTypes.map((x) => x)),
    "id": id,
  };
}

List<HandshakeResponse> handshakeResponseFromJson(String str) => List<HandshakeResponse>.from(json.decode(str).map((x) => HandshakeResponse.fromJson(x)));

String handshakeResponseToJson(List<HandshakeResponse> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HandshakeResponse {
  HandshakeResponse({
    required this.id,
    required this.channel,
    required this.successful,
    required this.version,
    required this.supportedConnectionTypes,
    required this.clientId,
    required this.advice,
  });

  String id;
  String channel;
  bool successful;
  String version;
  List<String> supportedConnectionTypes;
  String clientId;
  Advice advice;

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) => HandshakeResponse(
    id: json["id"],
    channel: json["channel"],
    successful: json["successful"],
    version: json["version"],
    supportedConnectionTypes: List<String>.from(json["supportedConnectionTypes"].map((x) => x)),
    clientId: json["clientId"],
    advice: Advice.fromJson(json["advice"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "channel": channel,
    "successful": successful,
    "version": version,
    "supportedConnectionTypes": List<dynamic>.from(supportedConnectionTypes.map((x) => x)),
    "clientId": clientId,
    "advice": advice.toJson(),
  };
}

class Advice {
  Advice({
    required this.reconnect,
    required this.interval,
    required this.timeout,
  });

  String reconnect;
  int interval;
  int timeout;

  factory Advice.fromJson(Map<String, dynamic> json) => Advice(
    reconnect: json["reconnect"],
    interval: json["interval"],
    timeout: json["timeout"],
  );

  Map<String, dynamic> toJson() => {
    "reconnect": reconnect,
    "interval": interval,
    "timeout": timeout,
  };
}

OfferOrAnswer offerOrAnswerFromJson(String str) => OfferOrAnswer.fromJson(json.decode(str));

String offerOrAnswerToJson(OfferOrAnswer data) => json.encode(data.toJson());

class OfferOrAnswer {
  OfferOrAnswer({
     this.sdp,
     this.type,
  });

  String? sdp;
  String? type;

  factory OfferOrAnswer.fromJson(Map<String, dynamic> json) => OfferOrAnswer(
    sdp: json["sdp"] ,
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "sdp": sdp,
    "type": type,
  };
}


Candidate candidateFromJson(String str) => Candidate.fromJson(json.decode(str));

String candidateToJson(Candidate data) => json.encode(data.toJson());

class Candidate {
  Candidate({
    this.mark,
    this.type,
    this.data,
  });

  String? mark;
  String? type;
  Data? data;

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
    mark: json["mark"],
    type: json["type"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "mark": mark,
    "type": type,
    "data": data?.toJson(),
  };
}

class Data {
  Data({
    required this.candidate,
     this.sdpMid,
     this.sdpMLineIndex,
  });

  String candidate;
  String? sdpMid;
  int? sdpMLineIndex;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    candidate: json["candidate"],
    sdpMid: json["sdpMid"],
    sdpMLineIndex: json["sdpMLineIndex"],
  );

  Map<String, dynamic> toJson() => {
    "candidate": candidate,
    "sdpMid": sdpMid,
    "sdpMLineIndex": sdpMLineIndex,
  };
}

CommandStart commandStartFromJson(String str) => CommandStart.fromJson(json.decode(str));

String commandStartToJson(CommandStart data) => json.encode(data.toJson());

class CommandStart {
  CommandStart({
    required this.type,
    required this.payload,
  });

  String type;
  StartPayload payload;

  factory CommandStart.fromJson(Map<String, dynamic> json) => CommandStart(
    type: json["type"],
    payload: StartPayload.fromJson(json["payload"]),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "payload": payload.toJson(),
  };
}

class StartPayload {
  StartPayload({
    required this.isVertical,
    required this.functions,
  });

  bool isVertical;
  List<String> functions;

  factory StartPayload.fromJson(Map<String, dynamic> json) => StartPayload(
    isVertical: json["isVertical"],
    functions: List<String>.from(json["functions"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "isVertical": isVertical,
    "functions": List<dynamic>.from(functions.map((x) => x)),
  };
}

CommandConfig commandConfigFromJson(String str) => CommandConfig.fromJson(json.decode(str));

String commandConfigToJson(CommandConfig data) => json.encode(data.toJson());

class CommandConfig {
  CommandConfig({
    required this.type,
    required this.payload,
  });

  String type;
  ConfigPayload payload;

  factory CommandConfig.fromJson(Map<String, dynamic> json) => CommandConfig(
    type: json["type"],
    payload: ConfigPayload.fromJson(json["payload"]),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "payload": payload.toJson(),
  };
}

class ConfigPayload {
  ConfigPayload({
    this.touch,
    this.gamepad,
    this.gyroscope,
    this.gyroscopeGamepad,
    this.move,
    this.mediaShare,
  });

  Touch? touch;
  GamepadConfig? gamepad;
  GyroscopeConfig? gyroscope;
  GyroscopeConfig? gyroscopeGamepad;
  GyroscopeConfig? move;
  MediaShare? mediaShare;

  factory ConfigPayload.fromJson(Map<String, dynamic> json) => ConfigPayload(
    touch: json["touch"] == null ? null : Touch.fromJson(json["touch"]),
    gamepad: json["gamepad"] == null ? null : GamepadConfig.fromJson(json["gamepad"]),
    gyroscope: json["gyroscope"] == null ? null : GyroscopeConfig.fromJson(json["gyroscope"]),
    gyroscopeGamepad: json["gyroscope_gamepad"] == null ? null : GyroscopeConfig.fromJson(json["gyroscope_gamepad"]),
    move: json["gyroscope_gamepad"] == null ? null : GyroscopeConfig.fromJson(json["gyroscope_gamepad"]),
    mediaShare: json["media_share"] == null ? null : MediaShare.fromJson(json["media_share"]),
  );

  Map<String, dynamic> toJson() => {
    "touch": touch?.toJson(),
    "gamepad": gamepad?.toJson(),
    "gyroscope": gyroscope?.toJson(),
    "gyroscope_gamepad": gyroscopeGamepad?.toJson(),
    "move": move?.toJson(),
    "media_share": mediaShare?.toJson(),
  };
}

class GamepadConfig {
  GamepadConfig({
    required this.buttons,
  });

  int buttons;

  factory GamepadConfig.fromJson(Map<String, dynamic> json) => GamepadConfig(
    buttons: json["buttons"],
  );

  Map<String, dynamic> toJson() => {
    "buttons": buttons,
  };
}

class GyroscopeConfig {
  GyroscopeConfig({
    required this.ok,
  });

  bool ok;

  factory GyroscopeConfig.fromJson(Map<String, dynamic> json) => GyroscopeConfig(
    ok: json["ok"],
  );

  Map<String, dynamic> toJson() => {
    "ok": ok,
  };
}

class MediaShare {
  MediaShare({
    required this.type,
  });

  String type;

  factory MediaShare.fromJson(Map<String, dynamic> json) => MediaShare(
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
  };
}

class Touch {
  Touch({
    required this.aspectRatio,
  });

  double aspectRatio;

  factory Touch.fromJson(Map<String, dynamic> json) => Touch(
    aspectRatio: json["aspectRatio"],
  );

  Map<String, dynamic> toJson() => {
    "aspectRatio": aspectRatio,
  };
}



























ShareRequestAnswer shareRequestAnswerFromJson(String str) => ShareRequestAnswer.fromJson(json.decode(str));

String shareRequestAnswerToJson(ShareRequestAnswer data) => json.encode(data.toJson());

class ShareRequestAnswer {
  ShareRequestAnswer({
    required this.type,
    required this.payload,
  });

  String type;
  ShareAnswerPayload payload;

  factory ShareRequestAnswer.fromJson(Map<String, dynamic> json) => ShareRequestAnswer(
    type: json["type"],
    payload: ShareAnswerPayload.fromJson(json["payload"]),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "payload": payload.toJson(),
  };
}

class ShareAnswerPayload {
  ShareAnswerPayload({
    required this.ok,
    required this.offset,
    required this.length,
    required this.duration,
    this.reason,
  });

  bool ok;
  double offset;
  int length;
  String? reason;
  double duration;

  factory ShareAnswerPayload.fromJson(Map<String, dynamic> json) => ShareAnswerPayload(
    ok: json["ok"],
    offset: json["offset"] is double ? json["offset"] : (json["offset"] as int).toDouble(),
    reason: json["reason"],
    length: json["length"],
    duration: json["duration"],
  );

  Map<String, dynamic> toJson() => {
    "ok": ok,
    "offset": offset,
    "reason": reason,
    "length": length,
    "duration": duration,
  };
}

ShareRequestStopAnswer shareRequestStopAnswerFromJson(String str) => ShareRequestStopAnswer.fromJson(json.decode(str));

String shareRequestStopAnswerToJson(ShareRequestStopAnswer data) => json.encode(data.toJson());

class ShareRequestStopAnswer {
  ShareRequestStopAnswer({
    required this.type,
    required this.payload,
  });

  String type;
  ShareStopAnswerPayload payload;

  factory ShareRequestStopAnswer.fromJson(Map<String, dynamic> json) => ShareRequestStopAnswer(
    type: json["type"],
    payload: ShareStopAnswerPayload.fromJson(json["payload"]),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "payload": payload.toJson(),
  };
}

class ShareStopAnswerPayload {
  ShareStopAnswerPayload({
    required this.ok,
    required this.keep,
    required this.keepID,
    required this.keepFullLength,
    required this.keepFullDuration,
    this.reason,
  });

  bool ok;
  double keep;
  int keepID;
  int keepFullLength;
  double keepFullDuration;
  String? reason;

  factory ShareStopAnswerPayload.fromJson(Map<String, dynamic> json) => ShareStopAnswerPayload(
    ok: json["ok"],
    keep: json["keep"],
    keepID: json["keep_id"],
    keepFullLength: json["keep_full_length"],
    keepFullDuration: json["keep_full_duration"],
    reason: json["reason"],
  );

  Map<String, dynamic> toJson() => {
    "ok": ok,
    "keep": keep,
    "keep_id": keepID,
    "reason": reason,
    "keep_full_length": keepFullLength,
    "keep_full_duration": keepFullDuration,
  };
}


