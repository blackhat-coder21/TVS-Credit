import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PsychometricTest extends StatefulWidget {
  final VoidCallback onCompleted;
  final String? userId; // Pass current user id
  final bool isPsychometricCompleted;

  const PsychometricTest({
    required this.onCompleted,
    required this.userId,
    required this.isPsychometricCompleted,
  });

  @override
  _PsychometricTestState createState() => _PsychometricTestState();
}

class _PsychometricTestState extends State<PsychometricTest> {
  Map<String, dynamic> answers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAnswers(); // Load saved answers when the widget is initialized
  }

  Future<void> _loadSavedAnswers() async {
    if (widget.userId != null) {
      // Fetch saved answers from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('psychometric_answers')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Store the fetched answers locally in the `answers` map
        setState(() {
          for (var doc in snapshot.docs) {
            answers[doc.id] = doc.data()['answer'];
          }
          isLoading = false; // Data has loaded
        });
      } else {
        setState(() {
          isLoading = false; // No answers found, continue
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching saved answers
          : FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('psychometric_test').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var questions = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    var question = questions[index];
                    return Card(
                      margin: const EdgeInsets.all(12.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${index + 1}: ${question['question']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: List.generate(
                                question['options'].length,
                                    (optionIndex) {
                                  return RadioListTile<String>(
                                    title: Text(question['options'][optionIndex]),
                                    value: question['options'][optionIndex],
                                    groupValue: answers[question.id], // Set the current answer from Firestore
                                    onChanged: (value) {
                                      setState(() {
                                        answers[question.id] = value!;
                                      });
                                      _saveAnswer(widget.userId, question.id, value);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton(
                  onPressed: () {
                    if (answers.length == questions.length) {
                      widget.onCompleted();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please answer all questions before submitting.'),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue, width: 2), // Blue outline
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding for better aesthetics
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

              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveAnswer(String? userId, String questionId, dynamic answer) async {
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('psychometric_answers')
          .doc(questionId)
          .set({
        'answer': answer,
      });
    }
  }
}
