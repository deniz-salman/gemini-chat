import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gemeini_chat/main.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SettingsViewModel extends ChangeNotifier {
  TextEditingController apiKeyController =
      TextEditingController(text: settingsBox.get('apiKey'));
  final formKey = GlobalKey<FormState>();

  Future<bool> checkKey() async {
    try {
      notifyListeners();
      await GenerativeModel(
              model: 'gemini-pro', apiKey: apiKeyController.text.trim())
          .generateContent([Content.text("test")]);
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  void setApiKey() async {
    await settingsBox.put('apiKey', apiKeyController.text.trim());
    notifyListeners();
  }
}
