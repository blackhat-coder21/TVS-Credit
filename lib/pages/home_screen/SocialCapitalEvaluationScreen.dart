import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialCapitalTest extends StatefulWidget {
  final VoidCallback onCompleted;
  final String? userId; // Pass current user id

  const SocialCapitalTest({required this.onCompleted, required this.userId});

  @override
  _SocialCapitalTestState createState() => _SocialCapitalTestState();
}

class _SocialCapitalTestState extends State<SocialCapitalTest> {
  Map<String, String> answers = {}; // Store answers as String
  Map<String, TextEditingController> controllers = {};
  List<String> questionIds = []; // Store question IDs

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('social_capital_test').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var questions = snapshot.data!.docs;
        questionIds = questions.map((q) => q.id).toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  var question = questions[index];
                  String questionId = question.id;
                  String questionText = question['question'];

                  // Initialize controller for each question if not already done
                  if (!controllers.containsKey(questionId)) {
                    controllers[questionId] = TextEditingController(text: answers[questionId] ?? '');
                  }

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${index + 1}. $questionText', // Display question number
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: controllers[questionId],
                            onChanged: (value) {
                              setState(() {
                                answers[questionId] = value; // Update answer on text change
                              });
                              _saveAnswerLocally(questionId, value); // Save to Shared Preferences
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Your answer...',
                            ),
                            minLines: 1,
                            maxLines: null, // Expands without limit
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            OutlinedButton(
              onPressed: () {
                if (answers.length == snapshot.data!.docs.length) {
                  _saveAnswersToFirebase(); // Save all answers to Firebase
                  widget.onCompleted();
                  _showSubmitConfirmation();
                } else {
                  _showErrorDialog();
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue, width: 2), // Blue outline
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding for better aesthetics
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.blue, // Blue text
                  fontWeight: FontWeight.bold, // Optional: make text bold
                ),
              ),
            ),

          ],
        );
      },
    );
  }

  void _saveAnswerLocally(String questionId, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(questionId, answer); // Save each answer locally
  }

  Future<void> _loadAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    for (String id in questionIds) {
      String? answer = prefs.getString(id);
      if (answer != null) {
        setState(() {
          answers[id] = answer; // Load saved answers into the state
          controllers[id]?.text = answer; // Load saved answer into the text controller
        });
      }
    }
  }

  void _saveAnswersToFirebase() {
    if (widget.userId != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref('users/${widget.userId}/tests/social_capital_test/answers');
      answers.forEach((questionId, answer) {
        dbRef.child(questionId).set(answer);
      });
    }
  }

  void _showSubmitConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Social Capital Test submitted!'),
    ));
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Please answer all questions before submitting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
