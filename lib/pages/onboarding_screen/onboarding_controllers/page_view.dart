import 'package:flutter/material.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/devices_utils/device_util.dart';
import 'onboarding_controller.dart';


class page_view extends StatelessWidget {
  const page_view({
    super.key,
    required this.controller_onboard,
  });

  final Onboarding_controller controller_onboard;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller_onboard.page_controller,
      // it will automatically pass the index
      onPageChanged: controller_onboard.update_page_indicator,
      children: [
        Column(
          children: [
            Image.asset(
              "assets/images/1.png",
              width: Device_util.mq(context).width,height: Device_util.mq(context).height*0.55,
            ),
            Text(Custom_text.board_1,style: Theme.of(context).textTheme.headlineMedium,textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(Custom_text.board_sub_1,style: Theme.of(context).textTheme.bodyMedium,textAlign: TextAlign.center,)
          ],
        ),
        Column(
          children: [
            Image.asset(
              "assets/images/2.png",
              width: Device_util.mq(context).width,height: Device_util.mq(context).height*0.55,
            ),
            Text(Custom_text.board_2,style: Theme.of(context).textTheme.headlineMedium,textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(Custom_text.board_sub_2,style: Theme.of(context).textTheme.bodyMedium,textAlign: TextAlign.center,)
          ],
        ),
        Column(
          children: [
            Image.asset(
              "assets/images/3.png",
              width: Device_util.mq(context).width,height: Device_util.mq(context).height*0.55,
            ),
            Text(Custom_text.board_3,style: Theme.of(context).textTheme.headlineMedium,textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(Custom_text.board_sub_3,style: Theme.of(context).textTheme.bodyMedium,textAlign: TextAlign.center,)
          ],
        )
      ],
    );
  }
}