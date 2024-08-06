import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemini_chat/main.dart';
import 'package:gemini_chat/models/chat.dart';
import 'package:gemini_chat/models/message.dart';
import 'package:gemini_chat/views/settings_view.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ChatViewModel extends ChangeNotifier {
  init() async {
    if (!kIsWeb) {
      applicationDocumentsDirectory =
          (await getApplicationDocumentsDirectory()).path;
      imageDir = p.join(applicationDocumentsDirectory, "imgs");
      await Directory(imageDir).create();
    }
    updateMessages();

    messagesBox.listenable().addListener(() => updateMessages());
  }

  ChatViewModel() {
    init();
  }
  final promptTextField = TextEditingController();
  final promptFocusNode = FocusNode();
  File? imageFile;
  bool isLoading = false;
  late String applicationDocumentsDirectory;
  late String imageDir;
  late CancelableOperation geminiRequest;
  List messageList = <Message>[];
  int? currentChatId;
  Map<String, Uint8List> imageMemoryCacheForWeb = {};

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
    if (kIsWeb) {
      imageMemoryCacheForWeb.clear();
      imageMemoryCacheForWeb.addAll({
        for (var message in messageList)
          if (message.promptImageId != null)
            message.promptImageId!: base64Decode(
                html.window.localStorage[message.promptImageId] as String)
      });
    }
    notifyListeners();
  }

  checkApiKey(context) {
    if (settingsBox.get('apiKey') == null || settingsBox.get('apiKey') == '') {
      SnackBar snackBar = SnackBar(
        content: const Text('Please set your API Key'),
        action: SnackBarAction(
          label: 'Set API Key',
          onPressed: () {
            if (MediaQuery.of(context).size.width > 768) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                        contentPadding: EdgeInsets.zero,
                        content: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: SizedBox(
                              width: .5.sw, child: const SettingsView()),
                        ));
                  });
            } else {
              Navigator.push(context,
                  PageRouteBuilder(pageBuilder: (context, animation, _) {
                return FadeTransition(
                    opacity: animation, child: const SettingsView());
              }));
            }
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

      if (kIsWeb && promptImage != null) {
        html.window.localStorage[promptImageId] = base64Encode(
            await get(Uri.parse(promptImage.path))
                .then((value) => value.bodyBytes));
        imageMemoryCacheForWeb[promptImageId] =
            base64Decode(html.window.localStorage[promptImageId] as String);
      } else {
        await imageFile?.copy(p.join(imageDir, promptImageId));
      }

      promptTextField.clear();
      imageFile = null;

      GenerateContentResponse? geminiResponse;
      isLoading = true;
      notifyListeners();
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();

      currentChatId ??= await chatsBox.add(Chat()..createdAt = DateTime.now());
      notifyListeners();

      final isImageNull = promptImage == null;

      final chatHistory = [
        for (var message in messageList) ...[
          Content("user", [TextPart(message.prompt)]),
          if (message.response != null)
            Content("model", [TextPart(message.response)]),
        ]
      ];

      final messageId = await messagesBox.add(Message()
        ..prompt = prompt
        ..promptImageId = promptImage == null ? null : promptImageId
        ..chatId = currentChatId!
        ..createdAt = DateTime.now());

      final model = GenerativeModel(
          model: isImageNull ? 'gemini-pro' : 'gemini-pro-vision',
          apiKey: await settingsBox.get('apiKey'));

      try {
        geminiRequest = CancelableOperation.fromFuture(isImageNull
                ? model
                    .startChat(history: chatHistory)
                    .sendMessage(Content("user", [TextPart(prompt)]))
                : model.generateContent([
                    Content.multi([
                      TextPart(prompt),
                      if (!isImageNull)
                        DataPart(
                            'image/png',
                            await get(Uri.parse(promptImage.path))
                                .then((value) => value.bodyBytes)),
                    ])
                  ]))
            .then((reponse) => geminiResponse = reponse);

        updateMessages();
        notifyListeners();
        await geminiRequest.valueOrCancellation();
      } catch (e) {
        isLoading = false;
        await messagesBox.delete(chatId);
        updateMessages();
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
      updateMessages();
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
