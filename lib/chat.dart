import 'package:flutter/material.dart';

import 'package:tmi/tmi.dart' as tmi;

// extension HexColor on Color {
//   /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
//   static Color fromHex(String hexString) {
//     final buffer = StringBuffer();
//     if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
//     buffer.write(hexString.replaceFirst('#', ''));
//     return Color(int.parse(buffer.toString(), radix: 16));
//   }

//   /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
//   String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
//       '${alpha.toRadixString(16).padLeft(2, '0')}'
//       '${red.toRadixString(16).padLeft(2, '0')}'
//       '${green.toRadixString(16).padLeft(2, '0')}'
//       '${blue.toRadixString(16).padLeft(2, '0')}';
// }

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

class Message {
  var name;
  var body;
  var color;

  Message(this.name, this.body, this.color);
}

class _ChatState extends State<ChatView> {
  List<Message> messages = [];
  var client;

  void initState() {
    this.client = tmi.Client(
      channels: "theo",
      secure: true,
    );

    client.connect();

    client.on("message", (channel, userstate, message, self) {
      if (self) return;

      print(userstate);

      print("${channel}| ${userstate['display-name']}: ${message}");

      setState(() => messages.add(
          Message(userstate['display-name'], message, userstate['color'])));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: messages
                  .map(
                    (e) => RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                              text: "${e.name}: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          TextSpan(text: e.body),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )),
          ),
          const TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a search term',
            ),
          ),
        ],
      ),
    );
  }
}
