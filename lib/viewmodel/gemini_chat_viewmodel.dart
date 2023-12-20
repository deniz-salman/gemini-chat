import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemeini_chat/constant.dart';
import 'package:google_gemini/google_gemini.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GeminiChatViewModel extends ChangeNotifier {
  init() async {
    applicationDocumentsDirectory =
        (await getApplicationDocumentsDirectory()).path;
    imageDir = p.join(applicationDocumentsDirectory, "imgs");
    await Directory(imageDir).create();
    collection = await BoxCollection.open('AppDB', {'chatLog'},
        path: applicationDocumentsDirectory);
    chatlog = await collection.openBox<Map>('chatLog');
    chatList = (await chatlog.getAllValues()).values.toList();

    notifyListeners();
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
  late String applicationDocumentsDirectory;
  late String imageDir;

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
    //4194304
    log((await imageFile?.length()).toString());

    if (!isLoading) {
      promptContoller.text = promptContoller.text.trim();
      if (promptContoller.text.isEmpty && imageFile == null) return;
      final prompt = promptContoller.text;

      String promptImageId = DateTime.now().microsecondsSinceEpoch.toString();
      File? promptImage = imageFile;
      await imageFile?.copy(p.join(imageDir, promptImageId));

      promptContoller.clear();
      imageFile = null;

      try {
        isLoading = true;
        notifyListeners();
        final chatId = DateTime.now().millisecondsSinceEpoch.toString();
        await chatlog.put(chatId, {
          "prompt": prompt,
          "promptImageId": promptImage == null ? null : promptImageId,
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
          "promptImageId": promptImage == null ? null : promptImageId,
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
