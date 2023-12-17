import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:google_gemini_demo/constant.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class GeminiChatViewModel extends ChangeNotifier {
  init() async {
    collection = await BoxCollection.open(
      'AppDB',
      {'chatLog'},
      path: (await getApplicationDocumentsDirectory()).path,
    );
    chatlog = await collection.openBox<Map>('chatLog');
    chatList = (await chatlog.getAllValues()).values.toList();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  GeminiChatViewModel() {
    init();
  }
  late BoxCollection collection;
  late CollectionBox chatlog;
  final gemini = GoogleGemini(apiKey: geminiApiKey);
  final promptContoller = TextEditingController();
  File? imageFile;
  List? chatList;
  bool isLoading = false;

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      imageFile = File(image.path);
      notifyListeners();
    } on PlatformException catch (e) {
      log('Failed to pick image: $e');
    }
  }

  removeImage() {
    imageFile = null;
    notifyListeners();
  }

  showErrorMessage(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"))
            ],
          );
        });
  }

  sendPrompt(context) async {
    if (!isLoading) {
      promptContoller.text = promptContoller.text.trim();
      if (promptContoller.text.isEmpty && imageFile == null) return;
      final prompt = promptContoller.text;
      File? promptImage = imageFile;
      promptContoller.clear();
      imageFile = null;

      try {
        isLoading = true;
        notifyListeners();
        final chatId = DateTime.now().millisecondsSinceEpoch.toString();
        await chatlog.put(chatId, {
          "prompt": prompt,
          "promptImage": promptImage == null
              ? null
              : base64Encode(promptImage.readAsBytesSync()),
          "response": ""
        });
        chatList = (await chatlog.getAllValues()).values.toList();
        notifyListeners();
        final geminiResponse = promptImage == null
            ? await gemini.generateFromText(prompt)
            : await gemini.generateFromTextAndImages(
                query: prompt, image: promptImage);

        isLoading = false;
        notifyListeners();
        await chatlog.put(chatId, {
          "prompt": prompt,
          "promptImage": promptImage == null
              ? null
              : base64Encode(promptImage.readAsBytesSync()),
          "response": geminiResponse.text
        });
        chatList = (await chatlog.getAllValues()).values.toList();
        notifyListeners();
      } catch (e) {
        isLoading = false;
        notifyListeners();
        log(e.toString());
        showErrorMessage(context, e.toString());
      }
    }
  }
}
