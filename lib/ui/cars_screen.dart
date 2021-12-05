import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/ui/gyroscope.dart';
import 'package:slowbro/ui/touchscreen.dart';
import 'package:wakelock/wakelock.dart';

class CarsScreen extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;

  const CarsScreen(
      {Key? key, required this.provider, required this.pointerOptions})
      : super(key: key);

  @override
  _CarsScreenState createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  bool isTouchScreen = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]);
    Wakelock.enable();
  }

  onChangeInput() {
    setState(() {
      isTouchScreen = false;
    });
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
    Wakelock.disable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isTouchScreen
          ? TouchScreen(
        provider: widget.provider,
        pointerOptions: widget.pointerOptions,
        onTouchPressed: onChangeInput,
      )
          : Gyroscope(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: onChangeInput),
    );
  }
}
