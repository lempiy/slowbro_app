import 'dart:convert';

import 'package:slowbro/api/peer_provider.dart';
import 'package:slowbro/api/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:slowbro/ui/control_screen.dart';

class WaitRoomView extends StatefulWidget {
  final PeerProvider provider;
  final StartPayload start;

  const WaitRoomView({Key? key, required this.provider, required this.start}) : super(key: key);

  @override
  State<WaitRoomView> createState() => _WaitRoomViewState();
}

class _WaitRoomViewState extends State<WaitRoomView> {
  StartPayload? startData;
  ConfigPayload? config;

  @override
  void initState() {
    confirmAndWaitConfig();
    super.initState();
  }



  void confirmAndWaitConfig() async {
    final reply = jsonEncode({"type": "start_confirm", "payload": {}});
    widget.provider.sendTextMessage(reply);
    print("waiting config...");
    final event = await widget.provider.textMessages.map((text) => commandConfigFromJson(text)).firstWhere((event) => event.type == "config");
    print(event);
    final r = jsonEncode({"type": "config_confirm", "payload": {}});
    widget.provider.sendTextMessage(r);
    setState(() {
      config = event.payload;
    });
    print(event.payload.touch?.aspectRatio);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ControlScreen(provider: widget.provider, pointerOptions: event.payload, start: widget.start),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      )
    );
  }

  Widget _olDbuild(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(child: Text("Select Demo", style: TextStyle(
                  fontSize: 30,
                ),)),
              ),
              // Expanded(
              //   flex: 7,
              //   child: GridView.count(crossAxisCount: 2,
              //       padding: EdgeInsets.zero,
              //       primary: false,
              //       shrinkWrap: true,
              //       children: [
              //         IconButton(icon: Icon(Icons.fitness_center), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "fitness"}});
              //           widget.provider.sendTextMessage(event);
              //           await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "fitness");
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => FitnessView(provider: widget.provider),
              //           ));
              //         }),
              //         IconButton(icon: Icon(Icons.location_searching_outlined), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "archer"}});
              //           widget.provider.sendTextMessage(event);
              //           final approve = await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "archer");
              //           final options = PointerOptions.fromJson(approve.payload!.options!);
              //           print(options.aspectRatio);
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => ArcherScreen(provider: widget.provider, pointerOptions: options,),
              //           ));
              //         }),
              //         IconButton(icon: Icon(Icons.gamepad), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "tanks"}});
              //           widget.provider.sendTextMessage(event);
              //           final approve = await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "tanks");
              //           final options = ConfigPayload.fromJson(approve.payload!.options!);
              //           print(options.aspectRatio);
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => TanksScreen(provider: widget.provider, pointerOptions: options,),
              //           ));
              //         }),
              //         IconButton(icon: Icon(Icons.wifi_protected_setup), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "cubes"}});
              //           widget.provider.sendTextMessage(event);
              //           final approve = await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "cubes");
              //           final options = PointerOptions.fromJson(approve.payload!.options!);
              //           print(options.aspectRatio);
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => CubesScreen(provider: widget.provider, pointerOptions: options,),
              //           ));
              //         }),
              //         IconButton(icon: Icon(Icons.directions_car_rounded), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "cars"}});
              //           widget.provider.sendTextMessage(event);
              //           final approve = await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "cars");
              //           final options = PointerOptions.fromJson(approve.payload!.options!);
              //           print(options.aspectRatio);
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => CarsScreen(provider: widget.provider, pointerOptions: options,),
              //           ));
              //         }),
              //         IconButton(icon: Icon(Icons.videocam), iconSize: 50, onPressed: () async {
              //           final event = jsonEncode({"type": "select-demo", "payload": {"demo": "moments"}});
              //           widget.provider.sendTextMessage(event);
              //           final approve = await widget.provider.textMessages.map((text) => selectDemoEventFromJson(text)).firstWhere((event) => event.type == "select-demo" && event.payload?.demo == "moments");
              //           final options = PointerOptions.fromJson(approve.payload!.options!);
              //           print(options.aspectRatio);
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (context) => MomentsScreen(provider: widget.provider, pointerOptions: options,),
              //           ));
              //         }),
              //       ]),
              // ),
            ],
          ),
        )
    );
  }
}
