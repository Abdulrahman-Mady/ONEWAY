import '/components/assistant_suggestion/assistant_suggestion_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'voice_assistant_interface_widget.dart'
    show VoiceAssistantInterfaceWidget;
import 'package:flutter/material.dart';

class VoiceAssistantInterfaceModel
    extends FlutterFlowModel<VoiceAssistantInterfaceWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for AssistantSuggestion.
  late AssistantSuggestionModel assistantSuggestionModel1;
  // Model for AssistantSuggestion.
  late AssistantSuggestionModel assistantSuggestionModel2;
  // Model for AssistantSuggestion.
  late AssistantSuggestionModel assistantSuggestionModel3;
  // Model for AssistantSuggestion.
  late AssistantSuggestionModel assistantSuggestionModel4;

  @override
  void initState(BuildContext context) {
    assistantSuggestionModel1 =
        createModel(context, () => AssistantSuggestionModel());
    assistantSuggestionModel2 =
        createModel(context, () => AssistantSuggestionModel());
    assistantSuggestionModel3 =
        createModel(context, () => AssistantSuggestionModel());
    assistantSuggestionModel4 =
        createModel(context, () => AssistantSuggestionModel());
  }

  @override
  void dispose() {
    assistantSuggestionModel1.dispose();
    assistantSuggestionModel2.dispose();
    assistantSuggestionModel3.dispose();
    assistantSuggestionModel4.dispose();
  }
}
