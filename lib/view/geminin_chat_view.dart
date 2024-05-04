import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemeini_chat/subview/chat_view.dart';
import 'package:gemeini_chat/viewmodel/gemini_chat_viewmodel.dart';

final geminiChatViewModelProvider =
    ChangeNotifierProvider((ref) => GeminiChatViewModel());

class GeminiChatView extends ConsumerWidget {
  const GeminiChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(geminiChatViewModelProvider);

    var addImageButton = IconButton(
        onPressed: () {
          viewModel.pickImage();
        },
        icon: const Icon(Icons.add_photo_alternate_outlined));

    final messageField = Expanded(
      child: TextField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Message Gemini...',
        ),
        keyboardType: TextInputType.multiline,
        controller: viewModel.promptTextField,
        onSubmitted: (value) {
          viewModel.sendPrompt(context);
        },
        onTapOutside: (PointerDownEvent evt) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        maxLines: 10,
        minLines: 1,
      ),
    );

    final sendButton = viewModel.isLoading
        ? Stack(
            alignment: Alignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
              IconButton(
                  onPressed: () => viewModel.geminiRequest.cancel(),
                  icon: const Icon(Icons.stop))
            ],
          )
        : IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              viewModel.sendPrompt(context);
              FocusScope.of(context).requestFocus(FocusNode());
            },
          );

    return Scaffold(
        appBar: AppBar(
          title: const Text('Gemini Chat'),
        ),
        body: Column(
          children: [
            const ChatView(),
            Container(
              color: Colors.blueGrey,
              child: Row(
                children: [
                  if (viewModel.imageFile == null) addImageButton,
                  messageField,
                  sendButton,
                ],
              ),
            ),
          ],
        ));
  }
}
