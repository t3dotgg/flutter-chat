import 'package:flutter/material.dart';

import 'package:tmi/tmi.dart' as tmi;

class ChatView extends StatefulWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<ChatView> createState() => _ChatState();
}

class _ChatState extends State<ChatView> {
  List<String> messages = [];
  var client;

  void initState() {
    this.client = tmi.Client(
      channels: "theo",
      secure: true,
    );

    client.connect();

    client.on("message", (channel, userstate, message, self) {
      if (self) return;

      print("${channel}| ${userstate['display-name']}: ${message}");

      setState(() => messages.add("${userstate['display-name']}: ${message}"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      children: messages.map((e) => Text(e)).toList(),
    ));
  }
}
