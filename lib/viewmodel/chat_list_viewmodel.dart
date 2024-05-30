import 'package:flutter/material.dart';
import 'package:gemini_chat/main.dart';
import 'package:gemini_chat/model/chat.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatListViewModel extends ChangeNotifier {
  ChatListViewModel() {
    init();
  }
  List chatList = <Chat>[];
  List chatListKeys = <int>[];
  init() {
    updateLists();
    chatsBox.listenable().addListener(() => updateLists());
  }

  updateLists() {
    chatList = chatsBox.values.toList().cast<Chat>();
    chatListKeys = chatsBox.keys.toList();
    notifyListeners();
  }

  deleteChat(int id) {
    chatsBox.delete(id);
    messagesBox.deleteAll(messagesBox.keys
        .where((element) => messagesBox.get(element)!.chatId == id));
    updateLists();
  }
}
