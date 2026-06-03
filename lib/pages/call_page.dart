import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:mox_beta/services/zego_config.dart';

class CallPage extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;

  const CallPage({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      callID: callID,
      userID: userID,
      userName: userName,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
