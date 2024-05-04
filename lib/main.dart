import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemeini_chat/view/geminin_chat_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences sharedPrefences;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefences = await SharedPreferences.getInstance();
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
          home: const GeminiChatView(),
        ),
      ),
    );
  }
}
