import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'TestAlreadyAttemptedScreen.dart';

class SocialCapitalTest extends StatefulWidget {
  @override
  _SocialCapitalTestState createState() => _SocialCapitalTestState();
}

class _SocialCapitalTestState extends State<SocialCapitalTest> {
  Map<String, String> answers = {}; // Store answers as String
  Map<String, TextEditingController> controllers = {};
  List<String> questionIds = []; // Store question IDs
  String? userId; // User ID from FirebaseAuth
  bool isLoading = true;
  bool testAttempted = false; // Track if the test has already been attempted

  @override
  void initState() {
    super.initState();
    _checkTestAttempted(); // Check if the test has been attempted
    _fetchUserIdAndLoadAnswers();
  }

  Future<void> _checkTestAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    testAttempted = prefs.getBool('testAttempted') ?? false; // Check saved preference
    if (testAttempted) {
      // If the test was already attempted, navigate to the already attempted screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => TestAlreadyAttemptedScreen()),
      );
    }
  }

  Future<void> _fetchUserIdAndLoadAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await _loadAnswers(); // Load saved answers for the current user
    }
    setState(() {
      isLoading = false; // Data has finished loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Capital Test'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildTimer(),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('social_capital_test').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var questions = snapshot.data!.docs;
                questionIds = questions.map((q) => q.id).toList();

                return ListView.builder(
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
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () {
                if (answers.length == questionIds.length) {
                  _saveAnswersToFirebase(); // Save all answers to Firebase
                  _markTestAsAttempted(); // Mark the test as attempted
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
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.access_time, color: Colors.blue),
          TimerCountdown(
            format: CountDownTimerFormat.minutesSeconds,
            endTime: DateTime.now().add(const Duration(minutes: 10)),
            onEnd: () {
              // Handle what happens when the timer ends
              _showTimeUpDialog();
            },
            timeTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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

  void _saveAnswersToFirebase() async {
    if (userId != null) {
      // Store answers in Firestore
      CollectionReference answersRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('tests').doc('social_capital_test').collection('answers');

      // Clear existing answers to avoid duplicates
      await answersRef.get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Save each answer to Firestore
      for (String questionId in answers.keys) {
        await answersRef.doc(questionId).set({
          'answer': answers[questionId],
        });
      }
    }
  }

  void _markTestAsAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('testAttempted', true); // Mark the test as attempted
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Time Up'),
          content: const Text('Your time for the test is up. Please submit your answers.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSubmitConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Social Capital Test submitted!')),
    );
    // Navigate to the TestAlreadyAttemptedScreen after submission
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => TestAlreadyAttemptedScreen()),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Please answer all questions before submitting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
