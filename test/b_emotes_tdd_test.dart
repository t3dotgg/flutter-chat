import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseEmotes', () {
    test('single id, double replacement', () {
      final parsedMessage = parseEmotes(
        "Yo Kappas Kappa Kappa yo",
        {
          25: ["10-15", "16-21"]
        },
        onText: (e) => e,
        onEmote: (emoteId) => '[$emoteId]',
      );

      expect(
        parsedMessage,
        equals(
          ["Yo Kappas ", "[25]", " ", "[25]", " yo"],
        ),
      );
    });
  });
}

List<T> parseEmotes<T>(
  String message,
  Map<int, Iterable<String>> emotes, {
  required T Function(String text) onText,
  required T Function(int emoteId) onEmote,
}) {
  final matches = <_EmoteMatch>[];

  /// Expand into individual emote matches
  for (final e in emotes.entries) {
    final emoteId = e.key;
    final spans = e.value;

    for (final span in spans) {
      final indicies = span.split("-").map(int.parse);
      matches.add(_EmoteMatch(emoteId, indicies.first, indicies.last));
    }
  }

  /// Sort by start index
  matches.sort((a, b) => a.startIndex.compareTo(b.startIndex));

  final chunks = <T>[];

  _EmoteMatch? previousMatch;
  for (final match in matches) {
    final startIndex = previousMatch?.endIndex ?? 0;
    final endIndex = match.startIndex;

    chunks.add(onText(message.substring(startIndex, endIndex)));
    chunks.add(onEmote(match.emoteId));

    previousMatch = match;
  }

  if (previousMatch != null) {
    final startIndex = previousMatch.endIndex;
    final endIndex = message.length;

    if (startIndex < endIndex) {
      chunks.add(onText(message.substring(startIndex, endIndex)));
    }
  }

  return chunks;
}

class _EmoteMatch {
  _EmoteMatch(this.emoteId, this.startIndex, this.endIndex);

  final int emoteId;
  final int startIndex;
  final int endIndex;
}
