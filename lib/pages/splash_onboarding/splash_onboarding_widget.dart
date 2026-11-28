import 'package:flutter/material.dart';

import '/features/onboarding/onboarding_flow.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'splash_onboarding_model.dart';
export 'splash_onboarding_model.dart';

/// Entry screen for first-launch onboarding, hosting the interactive 3-step
/// [OnewayOnboardingFlow] (Permissions -> Mobility Profile -> Quick Guide).
class SplashOnboardingWidget extends StatefulWidget {
  const SplashOnboardingWidget({super.key});

  static String routeName = 'SplashOnboarding';
  static String routePath = '/splashOnboarding';

  @override
  State<SplashOnboardingWidget> createState() => _SplashOnboardingWidgetState();
}

class _SplashOnboardingWidgetState extends State<SplashOnboardingWidget> {
  late SplashOnboardingModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashOnboardingModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnewayOnboardingFlow(
      onFinished: (_) async {
        if (mounted) {
          context.goNamed(AuthenticationWidget.routeName);
        }
      },
    );
  }
}
