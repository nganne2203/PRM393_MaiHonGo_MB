import 'package:flutter_test/flutter_test.dart';
import 'package:maihongo/features/flashcards/models/flashcard_session.dart';
import 'package:maihongo/features/vocabulary/models/vocabulary.dart';

void main() {
  test('X marks current card as not learned and moves to next card', () {
    final session = FlashcardSessionState.start(_cards());
    final answered =
        session.answerCurrent(FlashcardAnswerStatus.notLearned).moveNext();

    expect(answered.currentIndex, 1);
    expect(answered.notLearnedCards, 1);
    expect(answered.learnedCards, 0);
  });

  test('V marks current card as learned and moves to next card', () {
    final session = FlashcardSessionState.start(_cards());
    final answered =
        session.answerCurrent(FlashcardAnswerStatus.learned).moveNext();

    expect(answered.currentIndex, 1);
    expect(answered.learnedCards, 1);
    expect(answered.notLearnedCards, 0);
  });

  test('retry keeps the same card and does not change answer counts', () {
    final session = FlashcardSessionState.start(_cards());

    expect(session.currentIndex, 0);
    expect(session.answeredCards, 0);
    expect(session.currentCard?.word, '水');
  });

  test('last answered card creates correct summary result', () {
    final cards = _cards();
    final session = FlashcardSessionState.start(cards)
        .answerCurrent(FlashcardAnswerStatus.learned)
        .moveNext()
        .answerCurrent(FlashcardAnswerStatus.notLearned);

    expect(session.isLastCard, isTrue);

    final result = session.result(lessonId: 'lesson-1');
    expect(result.totalCards, 2);
    expect(result.learnedCount, 1);
    expect(result.notLearnedCount, 1);
    expect(result.accuracy, 50);
    expect(result.learnedCards.single.id, 'vocab-1');
    expect(result.notLearnedCards.single.id, 'vocab-2');
  });

  test('review not learned starts with only not learned cards', () {
    final result = FlashcardSessionState.start(_cards())
        .answerCurrent(FlashcardAnswerStatus.learned)
        .moveNext()
        .answerCurrent(FlashcardAnswerStatus.notLearned)
        .result(lessonId: 'lesson-1');

    final review = FlashcardSessionState.start(result.notLearnedCards);

    expect(review.totalCards, 1);
    expect(review.currentCard?.word, '学校');
  });

  test('restart all resets session status and index', () {
    final cards = _cards();
    final answered = FlashcardSessionState.start(cards)
        .answerCurrent(FlashcardAnswerStatus.learned)
        .moveNext();
    final restarted = FlashcardSessionState.start(answered.originalCards);

    expect(restarted.currentIndex, 0);
    expect(restarted.totalCards, 2);
    expect(restarted.answeredCards, 0);
    expect(restarted.unseenCards, 2);
  });
}

List<Vocabulary> _cards() => const [
      Vocabulary(
        id: 'vocab-1',
        word: '水',
        hiragana: 'みず',
        romaji: 'mizu',
        meaningVi: 'water',
        examples: [],
        tags: [],
        lessonId: 'lesson-1',
      ),
      Vocabulary(
        id: 'vocab-2',
        word: '学校',
        hiragana: 'がっこう',
        romaji: 'gakkou',
        meaningVi: 'school',
        examples: [],
        tags: [],
        lessonId: 'lesson-1',
      ),
    ];
