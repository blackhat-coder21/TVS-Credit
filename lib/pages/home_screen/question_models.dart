// Model class for a question in Psychometric Test
class Question {
  final String id;
  final String question;
  final List<String> options;
  Question({required this.id, required this.question, required this.options});
}

// Model class for a question in Social Capital Evaluation Test
class QuestionText {
  final String id;
  final String question;
  QuestionText({required this.id, required this.question});
}