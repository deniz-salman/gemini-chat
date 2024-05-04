import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemeini_chat/viewmodel/gemini_chat_viewmodel.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:path/path.dart' as p;

final geminiChatViewModelProvider =
    ChangeNotifierProvider((ref) => GeminiChatViewModel());

class GeminiChatView extends ConsumerWidget {
  const GeminiChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(geminiChatViewModelProvider);

    final image = viewModel.imageFile != null
        ? Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: Image.file(
                    viewModel.imageFile!,
                    fit: BoxFit.contain,
                  ),
                ),
                IconButton(
                  onPressed: viewModel.removeImage,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Container();

    final chat = Expanded(
        child: viewModel.imageFile != null
            ? image
            : viewModel.chatList == null
                ? const Center(child: CircularProgressIndicator())
                : viewModel.chatList!.isEmpty
                    ? Center(
                        child: Text("How can I help you today?",
                            style: Theme.of(context).textTheme.bodyLarge))
                    : ListView(
                        reverse: true,
                        children: [
                          for (final item in viewModel.chatList!)
                            Column(
                              children: [
                                ListTile(
                                  title: const MarkdownBlock(data: "### You"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item['promptImageId'] != null)
                                        ConstrainedBox(
                                          constraints: BoxConstraints.loose(
                                              Size(1.sw, .75.sh)),
                                          child: Image.file(
                                            File(p.join(viewModel.imageDir,
                                                item['promptImageId'])),
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      SelectableText(item['prompt']),
                                    ],
                                  ),
                                ),
                                if (item['response'] != null)
                                  ListTile(
                                    title: const MarkdownBlock(
                                        data: "###  Gemini"),
                                    subtitle: MarkdownBlock(
                                        data: item['response'] ?? ""),
                                  ),
                                12.verticalSpace,
                              ],
                            ),
                        ].reversed.toList()));

    final messageFieldFocusNode = FocusNode(
      onKey: (FocusNode node, RawKeyEvent evt) {
        if (!evt.isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
          if (evt is RawKeyDownEvent) {
            viewModel.sendPrompt(context);
          }
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
    );

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
        controller: viewModel.promptContoller,
        onSubmitted: (value) {
          viewModel.sendPrompt(context);
        },
        onTapOutside: (PointerDownEvent evt) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        maxLines: 10,
        minLines: 1,
        focusNode: messageFieldFocusNode,
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
            },
          );

    return Scaffold(
        appBar: AppBar(
          title: const Text('Gemini Chat'),
        ),
        body: Column(
          children: [
            chat,
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
