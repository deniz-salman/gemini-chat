import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_chat/views/chat_view.dart';
import 'package:gemini_chat/views/settings_view.dart';
import 'package:gemini_chat/viewmodels/chat_list_viewmodel.dart';

final chatListViewModelProvider =
    ChangeNotifierProvider((ref) => ChatListViewModel());

class ChatsView extends ConsumerWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListViewModel = ref.watch(chatListViewModelProvider);
    final chatViewModel = ref.watch(chatViewModelProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.black,
            width: .4,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Add New Chat"),
              onTap: () async {
                if (chatViewModel.currentChatId == null) {
                  Scaffold.of(context).openEndDrawer();
                  return;
                }
                chatViewModel.changeChat(null);
                Scaffold.of(context).openEndDrawer();
              },
            ),
            const Divider(height: 0),
            Expanded(
              flex: 7,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var id in chatListViewModel.chatListKeys.reversed)
                    ListTile(
                      title: Text("Chat $id"),
                      selected: chatViewModel.currentChatId == id,
                      selectedTileColor: Colors.grey[400],
                      selectedColor: Colors.black,
                      onTap: () {
                        chatViewModel.changeChat(id);
                        Scaffold.of(context).openEndDrawer();
                      },
                      trailing: IconButton(
                        onPressed: () {
                          chatListViewModel.deleteChat(id);
                          if (chatViewModel.currentChatId == id) {
                            chatViewModel.changeChat(null);
                          }
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 0),
            ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                  Navigator.push(context,
                      PageRouteBuilder(pageBuilder: (context, animation, _) {
                    return FadeTransition(
                        opacity: animation, child: const SettingsView());
                  }));
                }),
          ],
        ),
      ),
    );
  }
}
