import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/ui/dowloader.dart';
import 'package:slowbro/ui/gyroscope.dart';
import 'package:slowbro/ui/move.dart';
import 'package:slowbro/ui/icons.dart';
import 'package:slowbro/ui/touchscreen.dart';
import 'package:slowbro/ui/joystick.dart';
import 'package:wakelock/wakelock.dart';

import 'joystick.dart';

class ControlScreen extends StatefulWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;
  final StartPayload start;

  const ControlScreen(
      {Key? key, required this.provider, required this.pointerOptions, required this.start})
      : super(key: key);

  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  int currentInput = 0;

  @override
  void initState() {
    super.initState();
    if (widget.start.isVertical) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    Wakelock.enable();
  }

  nextInput() {
    setState(() {
      currentInput = getNextInput();
    });
  }

  getNextInput() {
    return currentInput + 1 == widget.start.functions.length ? 0 : currentInput + 1;
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
    Wakelock.disable();
  }

  IconData? getIcon(String inputName) {
    int i = widget.start.functions.indexOf(inputName);
    int next = i + 1 == widget.start.functions.length ? 0 : i + 1;
    return icons[widget.start.functions[next]];
  }

  Widget getFunctionView() {
    String inp = widget.start.functions[currentInput];
    int next = getNextInput();
    switch (inp) {
      case "touch":
        return TouchScreen(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: nextInput,
          toggleIcon: next == currentInput ? null : getIcon("touch"),
        );
      case "gamepad":
        return Joystick(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: nextInput,
          toggleIcon: next == currentInput ? null : getIcon("gamepad"),
        );
      case "move":
        return MoveView(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: nextInput,
          toggleIcon: next == currentInput ? null : getIcon("move"),
        );
      case "share_media":
        return Downloader(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: nextInput,
          toggleIcon: next == currentInput ? null : getIcon("share_media"),
        );
      case "gyroscope_gamepad":
        return Gyroscope(
          provider: widget.provider,
          pointerOptions: widget.pointerOptions,
          onTouchPressed: nextInput,
          toggleIcon: next == currentInput ? null : getIcon("gyroscope_gamepad"),
        );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getFunctionView(),
    );
  }
}
