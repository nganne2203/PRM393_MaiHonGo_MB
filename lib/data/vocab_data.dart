class VocabItem {
  final String kanji, kana, romaji, meaning, example, exampleTr, level;
  const VocabItem(this.kanji, this.kana, this.romaji, this.meaning,
      this.example, this.exampleTr, this.level);
}

const kVocab = <VocabItem>[
  VocabItem('猫', 'ねこ', 'neko', 'Mèo', '猫が好きです。', 'Tôi thích mèo.', 'N5'),
  VocabItem('犬', 'いぬ', 'inu', 'Chó', '犬と散歩する。', 'Đi dạo với chó.', 'N5'),
  VocabItem('水', 'みず', 'mizu', 'Nước', '水を飲みます。', 'Tôi uống nước.', 'N5'),
  VocabItem('本', 'ほん', 'hon', 'Sách', '本を読む。', 'Đọc sách.', 'N5'),
  VocabItem('学校', 'がっこう', 'gakkou', 'Trường học', '学校へ行く。', 'Đi học.', 'N5'),
  VocabItem(
      '友達', 'ともだち', 'tomodachi', 'Bạn bè', '友達と遊ぶ。', 'Chơi với bạn.', 'N4'),
  VocabItem(
      '電車', 'でんしゃ', 'densha', 'Tàu điện', '電車で行きます。', 'Đi bằng tàu.', 'N5'),
  VocabItem(
      '時間', 'じかん', 'jikan', 'Thời gian', '時間がない。', 'Không có thời gian.', 'N4'),
];

class CategoryItem {
  final String name, emoji;
  final int count, progress;
  final List<int> gradient; // ARGB ints
  final bool locked;
  const CategoryItem(this.name, this.emoji, this.count, this.progress,
      this.gradient, this.locked);
}

const kCategories = <CategoryItem>[
  CategoryItem('JLPT N5', '🌸', 800, 62, [0xFFFFB6C7, 0xFFFF8FB1], false),
  CategoryItem('JLPT N4', '🍃', 1500, 24, [0xFFA4DBA9, 0xFF7DCB8A], false),
  CategoryItem('Kanji', '🈁', 2136, 12, [0xFF8A7BFF, 0xFF6C5CE7], false),
  CategoryItem('Business', '💼', 420, 0, [0xFFFFD2A1, 0xFFFFA871], true),
  CategoryItem('Grammar', '📚', 200, 8, [0xFFB6DDF9, 0xFF7CC4F5], false),
  CategoryItem('JLPT N3', '🗻', 1800, 0, [0xFFC9B8FF, 0xFF9D85FF], true),
];

class QuizQuestion {
  final String kanji, kana;
  final List<String> options;
  final int correct;
  const QuizQuestion(this.kanji, this.kana, this.options, this.correct);
}

const kQuestions = <QuizQuestion>[
  QuizQuestion('猫', 'ねこ', ['Chó', 'Mèo', 'Cá', 'Chim'], 1),
  QuizQuestion('水', 'みず', ['Lửa', 'Đất', 'Nước', 'Gió'], 2),
  QuizQuestion(
      '学校', 'がっこう', ['Bệnh viện', 'Trường học', 'Thư viện', 'Công ty'], 1),
];
