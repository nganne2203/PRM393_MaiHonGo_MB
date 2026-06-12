import '../../vocabulary/models/vocabulary.dart';

enum FlashcardAnswerStatus {
  unseen,
  learned,
  notLearned,
}

class FlashcardSessionResult {
  final String? lessonId;
  final int totalCards;
  final List<Vocabulary> learnedCards;
  final List<Vocabulary> notLearnedCards;
  final DateTime completedAt;
  final bool synced;

  const FlashcardSessionResult({
    required this.lessonId,
    required this.totalCards,
    required this.learnedCards,
    required this.notLearnedCards,
    required this.completedAt,
    this.synced = false,
  });

  int get learnedCount => learnedCards.length;
  int get notLearnedCount => notLearnedCards.length;
  int get accuracy =>
      totalCards == 0 ? 0 : ((learnedCount / totalCards) * 100).round();
  List<String> get learnedVocabularyIds =>
      learnedCards.map((item) => item.id).where((id) => id.isNotEmpty).toList();
  List<String> get notLearnedVocabularyIds => notLearnedCards
      .map((item) => item.id)
      .where((id) => id.isNotEmpty)
      .toList();
}

class FlashcardSessionState {
  final List<Vocabulary> cards;
  final int currentIndex;
  final Map<String, FlashcardAnswerStatus> statuses;
  final List<Vocabulary> originalCards;

  const FlashcardSessionState({
    required this.cards,
    required this.currentIndex,
    required this.statuses,
    required this.originalCards,
  });

  factory FlashcardSessionState.start(List<Vocabulary> cards) {
    return FlashcardSessionState(
      cards: cards,
      currentIndex: 0,
      statuses: {
        for (final card in cards) card.id: FlashcardAnswerStatus.unseen
      },
      originalCards: cards,
    );
  }

  int get totalCards => cards.length;
  int get learnedCards => statuses.values
      .where((item) => item == FlashcardAnswerStatus.learned)
      .length;
  int get notLearnedCards => statuses.values
      .where((item) => item == FlashcardAnswerStatus.notLearned)
      .length;
  int get unseenCards => statuses.values
      .where((item) => item == FlashcardAnswerStatus.unseen)
      .length;
  int get answeredCards => learnedCards + notLearnedCards;
  bool get isEmpty => cards.isEmpty;
  bool get isLastCard => currentIndex >= cards.length - 1;
  Vocabulary? get currentCard =>
      cards.isEmpty ? null : cards[currentIndex.clamp(0, cards.length - 1)];

  FlashcardSessionState answerCurrent(FlashcardAnswerStatus status) {
    final card = currentCard;
    if (card == null) return this;
    return FlashcardSessionState(
      cards: cards,
      currentIndex: currentIndex,
      originalCards: originalCards,
      statuses: {
        ...statuses,
        card.id: status,
      },
    );
  }

  FlashcardSessionState moveNext() {
    if (cards.isEmpty || isLastCard) return this;
    return FlashcardSessionState(
      cards: cards,
      currentIndex: currentIndex + 1,
      statuses: statuses,
      originalCards: originalCards,
    );
  }

  FlashcardSessionResult result({required String? lessonId}) {
    final learned = <Vocabulary>[];
    final notLearned = <Vocabulary>[];

    for (final card in cards) {
      final status = statuses[card.id] ?? FlashcardAnswerStatus.unseen;
      if (status == FlashcardAnswerStatus.learned) {
        learned.add(card);
      } else if (status == FlashcardAnswerStatus.notLearned) {
        notLearned.add(card);
      }
    }

    return FlashcardSessionResult(
      lessonId: lessonId,
      totalCards: cards.length,
      learnedCards: learned,
      notLearnedCards: notLearned,
      completedAt: DateTime.now(),
    );
  }
}
