import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvs_test/pages/profile_page/Profile_screen.dart';
import 'dart:async';
import '../login_screen/LoginScreen.dart';
import '../profile_page/account_settings.dart';
import 'PsychometricTestScreen.dart';
import 'SocialCapitalEvaluationScreen.dart';
import 'TestAlreadyAttemptedScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isPsychometricCompleted = false;
  bool isSocialCapitalCompleted = false;
  Timer? _timer;
  int _remainingTime = 600; // 10 minutes in seconds
  bool isTestCompleted = false;
  User? user; // Firebase Auth User

  @override
  void initState() {
    _checkTestCompletionStatus();
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startTimer();
    _getCurrentUser();
  }

  void _checkTestCompletionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId != null) {
      // Access Realtime Database to get user data
      final userRef = FirebaseDatabase.instance.ref('users/$userId/test_attempted');
      final DatabaseEvent event = await userRef.once();

      // Access the snapshot from the event
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        setState(() {
          isTestCompleted = snapshot.value as bool? ?? false;
        });

        // Check if the test is already attempted
        if (isTestCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TestAlreadyAttemptedScreen(),
            ),
          );
        }
      } else {
        setState(() {
          isTestCompleted = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _submitTest();
        _showTimeUpDialog();
      }
    });
  }

  Future<void> _getCurrentUser() async {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
      user = FirebaseAuth.instance.currentUser;
    }
  }

  void _submitTest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isTestCompleted = true;
    });
    await prefs.setBool('isTestCompleted', true);
    await _updateTestStatusInFirebase();
    _timer?.cancel();
  }

  Future<void> _updateTestStatusInFirebase() async {
    if (user != null) {
      final userId = user!.uid;
      await FirebaseDatabase.instance.ref('users/$userId/test_attempted').set(true);
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Time\'s up!'),
          content: Text('You have run out of time for the test.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitTest();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TVS Credit'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Psychometric Test'),
            Tab(text: 'Social Capital Test'),
          ],
        ),
        actions: [
          if (!isTestCompleted)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: isTestCompleted
          ? TestAlreadyAttemptedScreen()
          : TabBarView(
        controller: _tabController,
        children: [
          PsychometricTest(
            onCompleted: _unlockSocialCapital,
            userId: user?.uid,
            isPsychometricCompleted: isPsychometricCompleted,
          ),
          isPsychometricCompleted
              ? SocialCapitalTest(onCompleted: _finalSubmit, userId: user?.uid)
              : const Center(child: Text('Complete the Psychometric Test first!')),
        ],
      ),
    );
  }

  // Add this method for the drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'Ankit'),
            accountEmail: Text(user?.email ?? 'No email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(user?.photoURL ?? 'assets/images/profile.jpg'),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
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

  void _unlockSocialCapital() {
    setState(() {
      isPsychometricCompleted = true;
      _tabController.animateTo(1); // Switch to the next tab
    });
    _saveCompletionStatus();
  }

  void _finalSubmit() {
    setState(() {
      isSocialCapitalCompleted = true;
      isTestCompleted = true;
    });
    _saveCompletionStatus();
    _updateTestStatusInFirebase();
    _showFinalSubmitConfirmation();
  }

  void _saveCompletionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPsychometricCompleted', isPsychometricCompleted);
    await prefs.setBool('isSocialCapitalCompleted', isSocialCapitalCompleted);
  }

  void _showFinalSubmitConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Social Capital Test submitted!'),
    ));
  }
}
