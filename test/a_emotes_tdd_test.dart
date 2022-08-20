import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('parseEmotes', () {
    test('single id, double replacement', () {
      /// "Yo Kappas Kappa Kappa yo"
      /// {25: ["10-15", "16-21"]}
      final exampleMessage = Message(
        "Yo Kappas Kappa Kappa yo",
        {
          25: [
            EmoteCursor.fromTwitchFormat("10-15"),
            EmoteCursor.fromTwitchFormat("16-21"),
          ]
        },
      );

      final parsedMessage = parseEmotes(exampleMessage);

      expect(
        parsedMessage,
        equals(
          [
            TextChunk("Yo Kappas "),
            EmoteChunk(25),
            TextChunk(" "),
            EmoteChunk(25),
            TextChunk(" yo"),
          ],
        ),
      );
    });
  });
}

List<MessageChunk> parseEmotes(Message message) {
  /// For each emote id
  ///   For each cursor span
  ///     Split message by cursor span
  ///       Unmatched is [TextChunk]
  ///       Matched is [EmojiChunk]

  final cursorEmoteIdPairs = <Tuple2<EmoteCursor, int>>[];

  /// Expand emote spec into a collection of cursor / emoteId pairs
  for (final entries in message.emoteSpec.entries) {
    final emoteId = entries.key;
    final cursors = entries.value;

    for (final cursor in cursors) {
      cursorEmoteIdPairs.add(Tuple2(cursor, emoteId));
    }
  }

  /// Sort by start index
  cursorEmoteIdPairs.sortByField((e) => e.item1);

  final text = message.messageText;
  final chunks = <MessageChunk>[];

  final maxEndIndex = text.length;

  Tuple2<EmoteCursor, int>? previousPair;
  for (final pair in cursorEmoteIdPairs) {
    final emoteId = pair.item2;

    final textStartIndex = previousPair?.item1.endIndex ?? 0;
    final textEndIndex = pair.item1.startIndex;

    previousPair = pair;

    chunks.add(TextChunk(text.substring(textStartIndex, textEndIndex)));
    chunks.add(EmoteChunk(emoteId));
  }

  final lastEmoteEndIndex = previousPair?.item1.endIndex;
  if (lastEmoteEndIndex != null && lastEmoteEndIndex < maxEndIndex) {
    chunks.add(TextChunk(text.substring(lastEmoteEndIndex, maxEndIndex)));
  }

  return chunks;
}

class Message {
  Message(this.messageText, this.emoteSpec);

  final String messageText;
  final EmoteSpec emoteSpec;
}

typedef EmoteSpec = Map<int, Iterable<EmoteCursor>>;

class EmoteCursor extends Comparable<EmoteCursor> {
  EmoteCursor(this.startIndex, this.endIndex);

  factory EmoteCursor.fromTwitchFormat(String payload) {
    final indicies = payload.split('-').map(int.parse);
    return EmoteCursor(indicies.first, indicies.last);
  }

  final int startIndex;
  final int endIndex;

  @override
  int compareTo(EmoteCursor other) {
    return startIndex.compareTo(other.startIndex);
  }

  @override
  String toString() => "EmoteCursor($startIndex,$endIndex)";
}

abstract class MessageChunk {}

class TextChunk extends MessageChunk {
  TextChunk(this.text);

  final String text;

  @override
  String toString() => 'TextChunk($text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TextChunk && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class EmoteChunk extends MessageChunk {
  EmoteChunk(this.emoteId);

  final int emoteId;

  @override
  String toString() => 'EmoteChunk($emoteId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmoteChunk && other.emoteId == emoteId;
  }

  @override
  int get hashCode => emoteId.hashCode;
}

extension ListX<T> on List<T> {
  void sortByField(Comparable Function(T e) selector) =>
      sort((a, b) => selector(a).compareTo(selector(b)));
}
