import '/components/button/button_widget.dart';
import '/components/dot/dot_widget.dart';
import '/components/onboarding_slide/onboarding_slide_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'splash_onboarding_widget.dart' show SplashOnboardingWidget;
import 'package:flutter/material.dart';

class SplashOnboardingModel extends FlutterFlowModel<SplashOnboardingWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for OnboardingSlide.
  late OnboardingSlideModel onboardingSlideModel;
  // Model for Dot.
  late DotModel dotModel1;
  // Model for Dot.
  late DotModel dotModel2;
  // Model for Dot.
  late DotModel dotModel3;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => ButtonModel());
    onboardingSlideModel = createModel(context, () => OnboardingSlideModel());
    dotModel1 = createModel(context, () => DotModel());
    dotModel2 = createModel(context, () => DotModel());
    dotModel3 = createModel(context, () => DotModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    onboardingSlideModel.dispose();
    dotModel1.dispose();
    dotModel2.dispose();
    dotModel3.dispose();
    buttonModel2.dispose();
  }
}
