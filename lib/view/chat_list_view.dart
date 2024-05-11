import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemeini_chat/view/chat_view.dart';
import 'package:gemeini_chat/viewmodel/chat_list_viewmodel.dart';

final chatListViewModelProvider =
    ChangeNotifierProvider((ref) => ChatListViewModel());

class ChatsView extends ConsumerWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListViewModel = ref.watch(chatListViewModelProvider);
    final chatViewModel = ref.watch(chatViewModelProvider);

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            onPressed: () async {
              if (chatViewModel.currentChatId == null) {
                Navigator.pop(context);
                return;
              }
              chatViewModel.changeChat(null);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Add New Chat",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.deepPurple,
                      ),
                ),
                const Icon(Icons.add)
              ],
            ),
          ),
          const Divider(),
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
                      Navigator.pop(context);
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
        ],
      ),
    );
  }
}
