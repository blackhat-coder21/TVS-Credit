import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

import '../pages/home_screen/PsychometricTestScreen.dart';
import '../pages/home_screen/SocialCapitalEvaluationScreen.dart';
import '../pages/onboarding_screen/onboarding.dart';

class SplaceController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    pageHandler();
  }

  void pageHandler() async {
    // Wait for 5 seconds before navigating
    await Future.delayed(const Duration(seconds: 5));

    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, fetch their role from the Realtime Database
      DatabaseReference userRef = FirebaseDatabase.instance.ref('userNew/${user.uid}');

      userRef.once().then((DatabaseEvent event) {
        // Check if the snapshot has data
        if (event.snapshot.value != null) {
          // User data exists; retrieve role
          var userData = event.snapshot.value as Map<dynamic, dynamic>;
          var role = userData['role'];

          // Navigate based on user role
          if (role == 'Loan Apply') {
            Get.offAll(PsychometricTest());
          } else if (role == 'Loan Approval') {
            Get.offAll(SocialCapitalTest());
          } else {
            // Default action if role is not recognized
            Get.offAll(Onboarding_screen());
          }
        } else {
          // Handle the case where user data does not exist
          print('User data does not exist in Realtime Database');
          Get.offAll(Onboarding_screen());
        }
      }).catchError((error) {
        // Handle any errors while fetching the user data
        print('Error fetching user data: $error');
        Get.offAll(Onboarding_screen());
      });
    } else {
      // User is not logged in, navigate to onboarding screen
      Get.offAll(Onboarding_screen());
    }
  }
}
