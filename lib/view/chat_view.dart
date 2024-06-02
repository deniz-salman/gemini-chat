import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemini_chat/subview/image_view.dart';
import 'package:gemini_chat/view/chat_list_view.dart';
import 'package:gemini_chat/viewmodel/chat_viewmodel.dart';
import 'package:path/path.dart' as p;
import 'package:markdown_widget/markdown_widget.dart';

final chatViewModelProvider = ChangeNotifierProvider((ref) => ChatViewModel());

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(chatViewModelProvider);

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
          focusNode: FocusNode(
            onKeyEvent: (FocusNode node, KeyEvent evt) {
              if (!HardwareKeyboard.instance.isShiftPressed &&
                  evt.logicalKey.keyLabel == 'Enter') {
                if (evt is KeyDownEvent) {
                  viewModel.sendPrompt(context);
                }
                return KeyEventResult.handled;
              } else {
                return KeyEventResult.ignored;
              }
            },
          )),
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
        drawer: const Drawer(
          child: ChatsView(),
        ),
        body: Column(
          children: [
            Expanded(
                child: viewModel.imageFile != null
                    ? const ImageView()
                    : viewModel.messageList.isEmpty
                        ? Center(
                            child: Text("How can I help you today?",
                                style: Theme.of(context).textTheme.bodyLarge))
                        : ListView(
                            reverse: true,
                            children: [
                              for (final item in viewModel.messageList)
                                Column(
                                  children: [
                                    ListTile(
                                      title:
                                          const MarkdownBlock(data: "### You"),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (item.promptImageId != null)
                                            ConstrainedBox(
                                              constraints: BoxConstraints.loose(
                                                  Size(1.sw, .75.sh)),
                                              child: Image.file(
                                                File(p.join(viewModel.imageDir,
                                                    item.promptImageId)),
                                                fit: BoxFit.scaleDown,
                                              ),
                                            ),
                                          SelectableText(item.prompt),
                                        ],
                                      ),
                                    ),
                                    if (item.response != null)
                                      ListTile(
                                        title: const MarkdownBlock(
                                            data: "###  Gemini"),
                                        subtitle: MarkdownBlock(
                                            data: item.response ?? ""),
                                      ),
                                    12.verticalSpace,
                                  ],
                                ),
                            ].reversed.toList())),
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
