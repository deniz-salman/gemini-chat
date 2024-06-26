// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemini_chat/main.dart';
import 'package:gemini_chat/views/chat_view.dart';
import 'package:gemini_chat/viewmodels/chat_viewmodel.dart';
import 'package:gemini_chat/viewmodels/settings_viewmodel.dart';
import 'package:url_launcher/url_launcher_string.dart';

final settingsViewModelProvider =
    ChangeNotifierProvider((ref) => SettingsViewModel());

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsViewModel settingsViewModel =
        ref.watch(settingsViewModelProvider);
    final ChatViewModel chatViewModel = ref.watch(chatViewModelProvider);

    Future<bool> apiKeyIsValid(BuildContext context) async {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  10.verticalSpace,
                  const Text('Checking API Key...'),
                ],
              ),
            );
          });
      return await settingsViewModel.checkKey().then((value) {
        Navigator.pop(context);
        return value;
      });
    }

    final apiKey = ListTile(
        title: const Text('API Key'),
        subtitle:
            Text(settingsBox.get('apiKey', defaultValue: 'No API Key Set')),
        onLongPress: () {
          if (settingsBox.get('apiKey') == null) {
            return;
          }
          Clipboard.setData(ClipboardData(text: settingsBox.get('apiKey')));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Key copied to clipboard'),
            ),
          );
        },
        onTap: () =>
            apiKeyEnterDialog(context, settingsViewModel, apiKeyIsValid));

    final clearChat = ListTile(
      enabled: chatsBox.isNotEmpty,
      title: const Text('Clear all chat history'),
      onTap: () {
        clearChatDialog(context, settingsViewModel, chatViewModel);
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          apiKey,
          clearChat,
        ],
      ),
    );
  }

  Future<dynamic> clearChatDialog(BuildContext context,
      SettingsViewModel settingsViewModel, ChatViewModel chatViewModel) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all chat history?'),
          content: const Text(
              'This will delete all chat history. Are you sure you want to continue?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                settingsViewModel.clearAllChat();
                chatViewModel.changeChat(null);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat history cleared'),
                  ),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> apiKeyEnterDialog(
      BuildContext context,
      SettingsViewModel settingsViewModel,
      Future<bool> Function(BuildContext context) apiKeyIsValid) {
    return showDialog(
      context: context,
      builder: (context) {
        settingsViewModel.apiKeyController.text =
            settingsBox.get('apiKey', defaultValue: '');
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('API Key'),
            content: Form(
              key: settingsViewModel.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    controller: settingsViewModel.apiKeyController,
                    decoration: const InputDecoration(
                      hintText: 'API Key',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter an API Key';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    launchUrlString('https://aistudio.google.com/app/apikey'),
                child: const Text('Get API Key'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (settingsViewModel.formKey.currentState!.validate()) {
                    if (await apiKeyIsValid(context)) {
                      saveApiKey(context, settingsViewModel);
                    } else {
                      showApiKeyValidError(context);
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void saveApiKey(BuildContext context, SettingsViewModel settingsViewModel) {
    Navigator.pop(context);
    settingsViewModel.setApiKey();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('API Key saved'),
    ));
  }

  Future<dynamic> showApiKeyValidError(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid API Key'),
            content: const Text(
                'The API Key you entered is invalid. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }
}
