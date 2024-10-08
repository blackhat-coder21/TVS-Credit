import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../utils/devices_utils/device_util.dart';

class login_logotitlesubtitle extends StatelessWidget {
  const login_logotitlesubtitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return
      Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          "assets/icons/tvs.jpg",
          height: Device_util.get_height(context) * 0.15,
        ),
        Text("Welcome back",style: Theme.of(context).textTheme.headlineMedium,),
        const SizedBox(width: 8,),
        Text("SignIn",style: Theme.of(context).textTheme.bodyMedium,),
      ],
    );
  }
}