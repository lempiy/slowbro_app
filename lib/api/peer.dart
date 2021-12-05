import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:slowbro/api/signaller.dart';
import 'package:slowbro/api/types.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final configuration = <String, dynamic>{'iceServers': []};

final offerSdpConstraints = <String, dynamic>{
  'mandatory': {
    'OfferToReceiveAudio': false,
    'OfferToReceiveVideo': false,
  },
  'optional': [],
};

final loopbackConstraints = <String, dynamic>{
  'mandatory': {},
  'optional': [
    {'DtlsSrtpKeyAgreement': true},
  ],
};

typedef void DataChannelClosedCallback();

class Peer {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  final String id;
  final SignallerTopic _topic;
  final String clientId;
  final DataChannelClosedCallback onClose;

  Peer(this.clientId, this._topic, {required this.onClose}) : this.id = _topic.id;

  bool get online => _dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen;

  void _onSignalingState(RTCSignalingState state) {
    print(state);
  }

  void _onIceGatheringState(RTCIceGatheringState state) {
    print(state);
  }

  void _onIceConnectionState(RTCIceConnectionState state) {
    print(state);
  }

  void _onCandidate(RTCIceCandidate candidate) {
    if (candidate.candidate == null) return;
    final msg = candidateToJson(Candidate(mark: clientId, type: "candidate",
        data: Data(candidate: candidate.candidate!, sdpMid: candidate.sdpMid, sdpMLineIndex: candidate.sdpMlineIndex)));
    print("onCandidate:  $msg");
    _topic.sendSignal(msg);
  }

  void _onRemoteCandidate(RTCIceCandidate candidate) async {
    final dsp = await _peerConnection!.getRemoteDescription();
    if (dsp == null) {
      sleep(Duration(milliseconds: 300));
       _onRemoteCandidate(candidate);
      return;
    }
    _peerConnection?.addCandidate(candidate);
  }

  void _onRenegotiationNeeded() {
    print('RenegotiationNeeded');
  }

  /// Send some sample messages and handle incoming messages.
  void _onDataChannel(RTCDataChannel dataChannel) {
    print("Channel opened");
    _dataChannel = dataChannel;
    _dataChannel!.onDataChannelState = _onDataChannelStateChange;
  }

  void _onDataChannelStateChange(RTCDataChannelState state) {
    switch (state) {
      case RTCDataChannelState.RTCDataChannelConnecting:
        // TODO: Handle this case.
        break;
      case RTCDataChannelState.RTCDataChannelOpen:
        // TODO: Handle this case.
        break;
      case RTCDataChannelState.RTCDataChannelClosing:
        // TODO: Handle this case.
        break;
      case RTCDataChannelState.RTCDataChannelClosed:
        return this.onClose();
    }
  }

  void messageText(String msg) {
    _dataChannel!.send(RTCDataChannelMessage(msg));
  }

  void messageBinary(Uint8List msg) {
    _dataChannel!.send(RTCDataChannelMessage.fromBinary(msg));
  }

  Stream<RTCDataChannelMessage> get messages => _dataChannel!.messageStream;
  Stream<bool> get onlineStatus => _dataChannel!.stateChangeStream.
    map((event) => event == RTCDataChannelState.RTCDataChannelOpen).asBroadcastStream();

  Future<void> prepare() async {
    _peerConnection =
        await createPeerConnection(configuration, loopbackConstraints);
    _peerConnection =
        await createPeerConnection(configuration, loopbackConstraints);

    _peerConnection!.onSignalingState = _onSignalingState;
    _peerConnection!.onIceGatheringState = _onIceGatheringState;
    _peerConnection!.onIceConnectionState = _onIceConnectionState;
    _peerConnection!.onIceCandidate = _onCandidate;
    _peerConnection!.onRenegotiationNeeded = _onRenegotiationNeeded;

    final _dataChannelDict = RTCDataChannelInit();
    _dataChannelDict.ordered = false;
    _dataChannelDict.maxRetransmitTime =-1;
    _dataChannelDict.maxRetransmits =-1;
    _dataChannelDict.protocol = 'sctp';
    _dataChannelDict.negotiated = true;

    _dataChannel =
        await _peerConnection!.createDataChannel('data', _dataChannelDict);
    _dataChannel!.onDataChannelState = _onDataChannelStateChange;
    _peerConnection!.onDataChannel = _onDataChannel;
  }

  Future<void> offer() async {
    if (_peerConnection == null) throw 'not prepared connection';
    _topic.stream!
        .map((event) => event.data == null ? null : candidateFromJson(event.data!))
        .where((event) {
          if (event == null) return false;
          if (event.mark == clientId) return false;
          return event.type == "candidate";
        })
        .map((event) => RTCIceCandidate(event!.data!.candidate,
            event.data!.sdpMid, event.data!.sdpMLineIndex))
        .listen(_onRemoteCandidate);
    print("Sending offer...");
    final description = await _peerConnection!.createOffer(offerSdpConstraints);
    await _peerConnection!.setLocalDescription(description);
    final offer = OfferOrAnswer(sdp: description.sdp!, type: description.type!);
    String sdp = jsonEncode(offer.toJson());
    print("Waiting answer...");
    final raw = await _topic.sendAndAwaitResponse(sdp, (response) {
      final data = offerOrAnswerFromJson(response);
      return data.type == "answer";
    });
    final data = offerOrAnswerFromJson(raw);
    final remoteSdp = RTCSessionDescription(data.sdp, data.type);
    print("Setting answer SDP...");
    await _peerConnection!.setRemoteDescription(remoteSdp);
  }

  void destroy() async {
    try {
      await _dataChannel?.close();
      await _peerConnection?.close();
      _peerConnection = null;
    } catch (e) {
      print(e.toString());
    }
  }
}
