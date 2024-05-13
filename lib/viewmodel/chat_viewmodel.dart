import 'dart:developer';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemeini_chat/main.dart';
import 'package:gemeini_chat/model/chat.dart';
import 'package:gemeini_chat/model/message.dart';
import 'package:gemeini_chat/view/settings_view.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ChatViewModel extends ChangeNotifier {
  init() async {
    applicationDocumentsDirectory =
        (await getApplicationDocumentsDirectory()).path;
    imageDir = p.join(applicationDocumentsDirectory, "imgs");
    await Directory(imageDir).create();
    updateMessages();

    messagesBox.listenable().addListener(() => updateMessages());
  }

  ChatViewModel() {
    init();
  }
  final promptTextField = TextEditingController();
  File? imageFile;
  bool isLoading = false;
  late String applicationDocumentsDirectory;
  late String imageDir;
  late CancelableOperation geminiRequest;
  List messageList = <Message>[];
  int? currentChatId;

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

  updateMessages() {
    messageList = messagesBox.values
        .toList()
        .cast<Message>()
        .where((element) => element.chatId == currentChatId)
        .toList();
    notifyListeners();
  }

  removeImage() {
    imageFile = null;
    notifyListeners();
  }

  changeChat(int? id) {
    currentChatId = id;
    updateMessages();
    notifyListeners();
  }

  checkApiKey(context) {
    if (settingsBox.get('apiKey') == null || settingsBox.get('apiKey') == '') {
      SnackBar snackBar = SnackBar(
        content: const Text('Please set your API Key'),
        action: SnackBarAction(
          label: 'Set API Key',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const Settingsview();
            }));
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
    return true;
  }

  sendPrompt(context) async {
    if (!checkApiKey(context)) {
      return;
    }

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

      currentChatId ??= await chatsBox.add(Chat()..createdAt = DateTime.now());
      notifyListeners();

      final messageId = await messagesBox.add(Message()
        ..prompt = prompt
        ..promptImageId = promptImage == null ? null : promptImageId
        ..chatId = currentChatId!
        ..createdAt = DateTime.now());

      final isImageNull = promptImage == null;
      final model = GenerativeModel(
          model: isImageNull ? 'gemini-pro' : 'gemini-pro-vision',
          apiKey: await settingsBox.get('apiKey'));

      final List<Content> content = isImageNull
          ? [
              for (var message in messageList) ...[
                Content("user", [TextPart(message.prompt)]),
                if (message.response != null)
                  Content("model", [TextPart(message.response)]),
              ]
            ]
          : [
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
        await geminiRequest.valueOrCancellation();
      } catch (e) {
        isLoading = false;
        await messagesBox.delete(chatId);
        notifyListeners();
        log(e.toString());
        showErrorMessage(context, e.toString());
      }

      if (geminiRequest.isCanceled ||
          !geminiRequest.isCompleted ||
          geminiResponse?.text == null) {
        await messagesBox.delete(chatId);
      } else {
        await messagesBox.put(
            messageId,
            Message()
              ..prompt = prompt
              ..promptImageId = promptImage == null ? null : promptImageId
              ..response = geminiResponse?.text
              ..chatId = currentChatId!
              ..createdAt = DateTime.now());
      }
      isLoading = false;
      notifyListeners();
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
