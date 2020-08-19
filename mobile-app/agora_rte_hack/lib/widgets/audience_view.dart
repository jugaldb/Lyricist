import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../utils/appID.dart';
import 'package:flutter/material.dart';

import 'broadcaster_status.dart';

class AudienceView extends StatefulWidget {
  final String channelName;
  AudienceView(this.channelName);
  @override
  _AudienceViewState createState() => _AudienceViewState();
}

class _AudienceViewState extends State<AudienceView> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  int broadcasterUid = 0;
  

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk and leave channel 
    AgoraRtcEngine.leaveChannel();
    AgoraRtcEngine.destroy();
    // AgoraRtcEngine.removeNativeView(_viewId);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    if (appID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await AgoraRtcEngine.enableWebSdkInteroperability(true);
    await AgoraRtcEngine.setParameters(
        '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}''');
  }

  /// Add agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    await AgoraRtcEngine.create(appID);
    await AgoraRtcEngine.enableVideo();
    await AgoraRtcEngine.muteLocalVideoStream(true);
    await AgoraRtcEngine.muteLocalAudioStream(true);
    await AgoraRtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await AgoraRtcEngine.setClientRole(ClientRole.Audience);
    await AgoraRtcEngine.joinChannel(null, widget.channelName, null, broadcasterUid);
  }

  /// agora event handlers
  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onError = (dynamic code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    };
    AgoraRtcEngine.onFirstRemoteAudioDecoded = (
      int uid,
      int elapsed,
    ){
      setState(() {
        final info = 'onFirstRemoteAudioDecode: ,uid: $uid';
        _infoStrings.add(info);
      });
    };
    /// Use this function to obtain the uid of the person who joined the channel 
    AgoraRtcEngine.onJoinChannelSuccess = (
      String channel,
      int uid,
      int elapsed,
    ) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        broadcasterUid = uid;
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    };

    AgoraRtcEngine.onFirstRemoteVideoFrame = (
      int uid,
      int width,
      int height,
      int elapsed,
    ) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    };
    print(_infoStrings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
        AgoraRenderWidget(broadcasterUid),
        Align(
          alignment: Alignment(0.9, -0.8),
          child: BroadcastingStatus(_users.length.toString()),
        ),
        ],      
      ),
    );
  }
}