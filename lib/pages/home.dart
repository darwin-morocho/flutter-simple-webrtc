import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:simple_webrtc/utils/signaling.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Signaling _signaling = Signaling();

  String _username = '';

  String _me, _him;

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _signaling.init();
    _signaling.onConnected = () {};
    _signaling.onLocalStream = (MediaStream stream) {
      _localRenderer.srcObject = stream;
      _localRenderer.mirror = true;
    };
    _signaling.onRemoteStream = (MediaStream stream) {
      _remoteRenderer.srcObject = stream;
      _remoteRenderer.mirror = true;
    };
    _signaling.onJoined = (bool isOk) {
      if (isOk) {
        _signaling.me = _username;
        setState(() {
          _me = _username;
        });
      }
    };
  }

  _initRenderers() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _signaling.dispose();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  _setMyUserName() {
    _signaling?.sendMesage('join', _username);
  }

  _call(String username) {
    _signaling.call(username);
  }

  _inputCall() {
    var username = '';
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            content: CupertinoTextField(
              placeholder: "Enter the username",
              onChanged: (text) => username = text,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                  onPressed: () {
                    _call(username);
                    Navigator.pop(context);
                  },
                  child: Text("MAKE CALL"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (_me == null)
              Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CupertinoTextField(
                      placeholder: "Enter your username",
                      textAlign: TextAlign.center,
                      onChanged: (text) {
                        _username = text;
                      },
                    ),
                    SizedBox(height: 20),
                    CupertinoButton(
                      onPressed: _setMyUserName,
                      color: Colors.blue,
                      child: Text("OK"),
                    )
                  ],
                ),
              ),
            if (_me != null)
              Positioned(
                left: 10,
                bottom: 20,
                child: Transform.scale(
                  scale: 0.3,
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: 480,
                    height: 640,
                    child: RTCVideoView(_localRenderer),
                  ),
                ),
              ),
            if (_me != null)
              Positioned(
                right: 10,
                bottom: 20,
                child: CupertinoButton(
                  onPressed: _inputCall,
                  child: Text("Call"),
                  color: Colors.blue,
                ),
              ),
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer),
            )
          ],
        ),
      ),
    );
  }
}
