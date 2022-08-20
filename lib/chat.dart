import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:tmi/tmi.dart' as tmi;

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';

final kappa =
    "https://static-cdn.jtvnw.net/emoticons/v2/80393/default/light/3.0";

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

class ChatPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final channelName = useState("lukepighetti");
    final userName = useState("");
    final oauthToken = useState("");
    final connected = useState(true);
    // This widget is the home page of your application. It is stateful, meaning
    // that it has a State object (defined below) that contains fields that affect
    // how it looks.

    // This class is the configuration for the state. It holds the values (in this
    // case the title) provided by the parent (in this case the App widget) and
    // used by the build method of the State. Fields in a Widget subclass are
    // always marked "final".

    if (connected.value == false) {
      return Column(children: [
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose Channel',
          ),
          onChanged: (current) => channelName.value = current.toString(),
          onSubmitted: (_c) => connected.value = true,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Username',
          ),
          onChanged: (current) => userName.value = current.toString(),
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Oauth token',
          ),
          onChanged: (current) => oauthToken.value = current.toString(),
        )
      ]);
    }
    return ChatView(channelName.value, userName.value, oauthToken.value);
  }

  @override
  State<ChatView> createState() => _ChatState();
}

class ChatView extends StatefulWidget {
  var channelName;
  var userName;
  var oauthToken;
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  ChatView(this.channelName, this.userName, this.oauthToken);
  // always marked "final".

  @override
  State<ChatView> createState() => _ChatState();
}

class Message {
  var name;
  var body;
  var color;

  var renderedContents;

  Message(this.name, this.body, this.color, this.renderedContents);
}

class _ChatState extends State<ChatView> {
  List<Message> messages = [];
  var client;

  var channel;

  void initState() {
    this.client = tmi.Client(
      channels: widget.channelName,
      secure: true,
    );

    client.connect();

    client.on("message", (channel, userstate, message, self) {
      if (self) return;

      print(
          "${channel}| ${userstate['display-name']}: ${userstate['color']}, ${userstate['emotes']}");

      var newColor = userstate['color'];
      if (newColor == "") newColor = "#000000";

      print(userstate['emotes'].runtimeType);
      final messageWithEmotes = parseEmotes(message, userstate['emotes']);

      print(messageWithEmotes);

      setState(() => messages.add(Message(
          userstate['display-name'], message, newColor, messageWithEmotes)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: [
                for (final e in messages.reversed)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "${e.name}: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HexColor.fromHex(e.color),
                          ),
                        ),
                        ...e.renderedContents,

                        /// TODO:
                        // parseEmotes()
                      ],
                    ),
                  ),
              ],
            ),
          ),
          MessageInput(widget.channelName, widget.userName, widget.oauthToken),
        ],
      ),
    );
  }
}

List<InlineSpan> parseEmotes(String messageText, Map emoteSpec) {
  final emoteIdByEmoteText = <String, String>{};

  for (final e in emoteSpec.entries) {
    final emoteId = e.key;
    final spans = e.value;

    for (final span in spans.sublist(0, 1)) {
      final startIndex = int.parse(span.split('-').first);
      final endIndex = int.parse(span.split('-').last);

      final emoteText = messageText.substring(startIndex, endIndex + 1);

      emoteIdByEmoteText[emoteText] = emoteId;
    }
  }

  final words = messageText.split(' ');

  final result = words.map<InlineSpan>((word) {
    if (emoteIdByEmoteText.containsKey(word)) {
      return WidgetSpan(
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Image.network(
            "https://static-cdn.jtvnw.net/emoticons/v2/${emoteIdByEmoteText[word]}/default/light/3.0",
            height: 18,
          ),
        ),
      );
    } else {
      return TextSpan(text: word + " ");
    }
  }).toList();

  print(emoteIdByEmoteText);

  return result;
}

class MessageInput extends HookWidget {
  MessageInput(this.channelName, this.userName, this.oauthToken, {super.key});

  final String channelName;

  final String userName;

  final String oauthToken;

  var client = http.Client();

  @override
  Widget build(BuildContext context) {
    final message = useState("");
    final controller = useTextEditingController();

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Choose Channel',
      ),
      onChanged: (current) => message.value = current.toString(),
      onEditingComplete: () async {
        print("CURRENTLY SENDING");
        print(controller.text);

        var postUrl =
            "https://hacky-chat-sends.vercel.app/api/chat-hell?channel=${channelName}&message=${Uri.encodeComponent(message.value)}&username=${userName}&token=${oauthToken}";

        // print(postUrl);

        controller.clear();

        /// Alternative A
        // http.post(Uri.parse(
        //   "https://hacky-chat-sends.vercel.app/api/chat-hell"
        //   "?channel=$channelName"
        //   "&message=${message.value}"
        //   "&username=$userName"
        //   "&token=$oauthToken",
        // ));

        /// Alternative B
        // final url =
        //     Uri.parse("https://hacky-chat-sends.vercel.app/api/chat-hell")
        //         .replace(
        //   queryParameters: {
        //     'channel': channelName,
        //     'message': message.value,
        //     'username': userName,
        //     'token': oauthToken,
        //   },
        // );

        // print(url);

        // var res = await Dio().get(postUrl);
        // print(res);
      },
    );
  }

  @override
  State<ChatView> createState() => _ChatState();
}
