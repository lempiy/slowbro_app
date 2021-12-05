import 'package:flutter/material.dart';
import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:slowbro/ui/touchpad.dart';

class TouchScreen extends StatelessWidget {
  final PeerProvider provider;
  final ConfigPayload pointerOptions;
  final void Function() onTouchPressed;
  final IconData? toggleIcon;

  const TouchScreen(
      {Key? key, required this.provider, required this.pointerOptions, required this.onTouchPressed, this.toggleIcon})
      : super(key: key);

  List<Widget> _getContent() {
    return [
      Expanded(flex: 1, child: Container()),
      Expanded(flex: 4, child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: TouchPad(provider: provider, pointerOptions: pointerOptions),
      )),
      Expanded(flex: 1, child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: IconButton(icon: Icon(this.toggleIcon, size: 40), onPressed: () => onTouchPressed()),
        ),
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (BuildContext context, Orientation orientation) {
      return Orientation.landscape == orientation ? Row(
        children: _getContent(),
      ) : Column(children: _getContent(),);
    });

  }
}
