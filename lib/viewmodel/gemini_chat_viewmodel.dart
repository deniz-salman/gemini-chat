import 'dart:developer';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemeini_chat/constant.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
    updateChatList();
    notifyListeners();
  }

  GeminiChatViewModel() {
    init();
  }
  late BoxCollection collection;
  late CollectionBox chatlog;
  final promptTextField = TextEditingController();
  File? imageFile;
  List? chatList;
  bool isLoading = false;
  late String applicationDocumentsDirectory;
  late String imageDir;
  late CancelableOperation geminiRequest;

  pickImage() async {
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

  updateChatList() async {
    chatList = (await chatlog.getAllValues()).values.toList();
    notifyListeners();
  }

  sendPrompt(context) async {
    if (!isLoading) {
      promptTextField.text = promptTextField.text.trim();
      if (promptTextField.text.isEmpty && imageFile == null) return;
      final prompt = promptTextField.text;

      String promptImageId = DateTime.now().microsecondsSinceEpoch.toString();
      File? promptImage = imageFile;
      await imageFile?.copy(p.join(imageDir, promptImageId));

      promptTextField.clear();
      imageFile = null;

      GenerateContentResponse? geminiResponse;
      isLoading = true;
      notifyListeners();
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      await chatlog.put(chatId, {
        "prompt": prompt,
        "promptImageId": promptImage == null ? null : promptImageId,
      });

      updateChatList();

      final isImageNull = promptImage == null;
      final model = GenerativeModel(
          model: isImageNull ? 'gemini-pro' : 'gemini-pro-vision',
          apiKey: geminiApiKey);

      final content = [
        Content.multi([
          TextPart(prompt),
          if (!isImageNull)
            DataPart('image/png', await promptImage.readAsBytes()),
        ])
      ];
      try {
        geminiRequest =
            CancelableOperation.fromFuture(model.generateContent(content))
                .then((reponse) => geminiResponse = reponse);

        notifyListeners();
        updateChatList();
        await geminiRequest.valueOrCancellation();
      } catch (e) {
        isLoading = false;
        notifyListeners();
        log(e.toString());
        showErrorMessage(context, e.toString());
      }

      if (geminiRequest.isCanceled ||
          !geminiRequest.isCompleted ||
          geminiResponse?.text == null) {
        await chatlog.delete((await chatlog.getAllValues()).keys.last);
      } else {
        await chatlog.put((await chatlog.getAllValues()).keys.last, {
          "prompt": prompt,
          "promptImageId": promptImage == null ? null : promptImageId,
          "response": geminiResponse?.text
        });
      }
      isLoading = false;
      notifyListeners();
      updateChatList();
    }
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
}
