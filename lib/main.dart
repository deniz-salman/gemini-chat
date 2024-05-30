import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemini_chat/model/chat.dart';
import 'package:gemini_chat/model/message.dart';
import 'package:gemini_chat/view/chat_view.dart';
import 'package:hive_flutter/hive_flutter.dart';

late Box<Chat> chatsBox;
late Box<Message> messagesBox;
late Box settingsBox;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await hiveInit();
  // await setDesktopConfig();
  runApp(const App());
}

hiveInit() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(MessageAdapter());
  chatsBox = await Hive.openBox<Chat>('chats');
  messagesBox = await Hive.openBox<Message>('messages');
  settingsBox = await Hive.openBox('settings');
}

setDesktopConfig() async {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    return;
  }
  await DesktopWindow.setMinWindowSize(const Size(800, 600));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: ProviderScope(
        child: MaterialApp(
          title: 'Gemini Chat',
          theme: ThemeData(primarySwatch: Colors.blueGrey),
          home: const ChatView(),
        ),
      ),
    );
  }
}
