import 'package:flutter_webrtc/webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef OnLocalStream(MediaStream stream);
typedef OnRemoteStream(MediaStream stream);
typedef OnConnected();
typedef OnJoined(bool isOk);

class Signaling {
  RTCPeerConnection _pc;
  OnLocalStream onLocalStream;
  OnRemoteStream onRemoteStream;
  OnConnected onConnected;
  OnJoined onJoined;

  String _me, _him;
  MediaStream _localStream;

  set me(String me) {
    this._me = me;
  }

  IO.Socket _socket;

  final sdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  init() async {
    final stream = await navigator.getUserMedia({
      "audio": true,
      "video": {
        "mandatory": {
          "minWidth": '480',
          "minHeight": '640',
          "minFrameRate": '30',
        },
        "facingMode": "user",
        "optional": [],
      }
    });

    onLocalStream(stream);
    _localStream = stream;

    _connect();
  }

  _createPeer() async {
    _pc = await createPeerConnection({
      "iceServers": [
        {
          "urls": [
            "stun:stun1.l.google.com:19302",
          ]
        },
      ]
    }, {});
    _pc.addStream(_localStream);
    _pc.onAddStream = (MediaStream remoteStream) {
      onRemoteStream(remoteStream);
    };
    _pc.onIceCandidate = (RTCIceCandidate candidate) {
      print(
          "onIceCandidate onIceCandidate onIceCandidate onIceCandidate onIceCandidate");
      if (_him != null && candidate != null) {
        print("sending candidate");
        this.sendMesage(
            'candidate', {"username": _him, "candidate": candidate.toMap()});
      }
    };
  }

  _connect() {
    _socket = IO.io('https://backend-simple-webrtc.herokuapp.com', <String, dynamic>{
      'transports': ['websocket'],
      'extraHeaders': {'foo': 'bar'} // optional
    });

    _socket.on('connect', (_) {
      print('connected');
      onConnected();
    });

    _socket.on('on-join', (isOk) {
      print("on-join $isOk");
      onJoined(isOk);
    });

    _socket.on('on-call', (data) async {
      print("on-call $data");
      await _createPeer();
      _him = data['username'];
      final offer = data['offer'];
      final desc = RTCSessionDescription(offer['sdp'], offer['type']);
      await _pc.setRemoteDescription(desc);
      final RTCSessionDescription answer =
          await _pc.createAnswer(sdpConstraints);
      await _pc.setLocalDescription(answer);
      sendMesage("answer", {
        "username": _him,
        "answer": answer.toMap() //{"type": answer.type, "sdp": answer.sdp}
      });
    });

    _socket.on('on-answer', (answer) async {
      print("on answer $answer");
      final desc = RTCSessionDescription(answer['sdp'], answer['type']);
      await _pc.setRemoteDescription(desc);
    });

    _socket.on('on-candidate', (data) async {
      print("on-candidate $data");
      RTCIceCandidate candidate = new RTCIceCandidate(
          data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      await _pc.addCandidate(candidate);
    });
  }

  call(String username) async {
    this._him = username;
    await _createPeer();
    final RTCSessionDescription desc = await _pc.createOffer(sdpConstraints);
    await _pc.setLocalDescription(desc);
    sendMesage("call", {"username": username, "offer": desc.toMap()});
  }

  sendMesage(String eventName, dynamic data) {
    _socket?.emit(eventName, data);
  }

  dispose() {
    _socket?.close();
    _socket = null;
  }
}
