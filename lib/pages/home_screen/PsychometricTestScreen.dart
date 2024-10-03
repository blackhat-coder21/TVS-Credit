import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tvs_test/pages/profile_page/account_settings.dart';
import 'dart:async';

import '../login_screen/LoginScreen.dart';
import 'TestAlreadyAttemptedScreen.dart';

class PsychometricTest extends StatefulWidget {
  @override
  _PsychometricTestState createState() => _PsychometricTestState();
}

class _PsychometricTestState extends State<PsychometricTest> {
  Map<String, dynamic> answers = {}; // Store user answers
  bool isLoading = true;
  String? userId; // User ID fetched from FirebaseAuth
  int timerSeconds = 600; // 10 minutes in seconds
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndLoadAnswers(); // Fetch the user ID and load answers
    _startTimer(); // Start the timer
  }

  // Fetch user ID from FirebaseAuth and load any saved answers
  Future<void> _fetchUserIdAndLoadAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      await _loadSavedAnswers();
      await _checkTestAttempted(); // Check if the test was already attempted
    }
  }

  // Check if the test was already attempted
  Future<void> _checkTestAttempted() async {
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('psychometric_answers')
          .get();
      if (snapshot.docs.isNotEmpty) {
        // Navigate to TestAlreadyAttemptedScreen if the test was attempted
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => TestAlreadyAttemptedScreen()));
      }
    }
  }

  // Load saved answers from Firestore
  Future<void> _loadSavedAnswers() async {
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('psychometric_answers')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Store the fetched answers in the `answers` map
        setState(() {
          for (var doc in snapshot.docs) {
            answers[doc.id] = doc.data()['answer'];
          }
          isLoading = false; // Data has loaded
        });
      }
      else {
        setState(() {
          isLoading = false; // No answers found, continue
        });
      }
    }
  }

  // Start the timer
  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (timerSeconds > 0) {
        setState(() {
          timerSeconds--;
        });
      } else {
        timer.cancel();
        // Navigate to the TestAlreadyAttemptedScreen if time is up
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => TestAlreadyAttemptedScreen()));
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psychometric Test'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(
                  '${(timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(timerSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Ankit'),
              accountEmail: Text('ankit@gmail.com'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 40), // Profile icon
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SettingsScreen()));
              },
            ),
          ListTile(
            leading: Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('psychometric_test').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var questions = snapshot.data!.docs; // List of questions
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
                                    groupValue: answers[question.id], // Set current answer from Firestore
                                    onChanged: (value) {
                                      setState(() {
                                        answers[question.id] = value!;
                                      });
                                      _saveAnswer(question.id, value);
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
                  onPressed: () async {
                    if (answers.length == questions.length) {
                      // Submit all answers
                      await _submitAllAnswers();
                      // Navigate to the TestAlreadyAttemptedScreen
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => TestAlreadyAttemptedScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please answer all questions before submitting.')),
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


  Future<void> _logout(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Logout',
                style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(
                color: Colors.grey,
                height: 20,
                thickness: 1,
                indent: 0,
                endIndent: 0,
              ),
              SizedBox(height: 16),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      // Clear the navigation stack and navigate to the login screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Login_screen()), // Replace with your login screen
                            (Route<dynamic> route) => false, // Removes all previous routes
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                    ),
                    child: Text('Yes, Logout'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                    ),
                    child: Text('Cancel'),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Save individual answer in Firestore as the user selects an option
  Future<void> _saveAnswer(String questionId, dynamic answer) async {
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

  // Submit all answers to Firestore
  Future<void> _submitAllAnswers() async {
    if (userId != null) {
      var batch = FirebaseFirestore.instance.batch();
      answers.forEach((questionId, answer) {
        var answerRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('psychometric_answers')
            .doc(questionId);
        batch.set(answerRef, {'answer': answer});
      });
      await batch.commit(); // Commit the batch to Firestore
    }
  }
}
