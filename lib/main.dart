import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemeini_chat/model/message.dart';
import 'package:gemeini_chat/model/chat.dart';
import 'package:gemeini_chat/view/chat_view.dart';
import 'package:hive_flutter/hive_flutter.dart';

late Box<Chat> chatsBox;
late Box<Message> messagesBox;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(MessageAdapter());
  chatsBox = await Hive.openBox<Chat>('chats');
  messagesBox = await Hive.openBox<Message>('messages');
  runApp(const App());
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
