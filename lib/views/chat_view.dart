import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemini_chat/subviews/image_view.dart';
import 'package:gemini_chat/views/chat_list_view.dart';
import 'package:gemini_chat/viewmodels/chat_viewmodel.dart';
import 'package:path/path.dart' as p;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter

final chatViewModelProvider = ChangeNotifierProvider((ref) => ChatViewModel());

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(chatViewModelProvider);

    bool isDesktop = MediaQuery.of(context).size.width > 768;

    var addImageButton = IconButton(
        onPressed: () {
          viewModel.pickImage();
        },
        icon: const Icon(Icons.add_photo_alternate_outlined));

    viewModel.promptFocusNode.onKeyEvent = (FocusNode node, KeyEvent evt) {
      viewModel.promptFocusNode.requestFocus();
      if (!HardwareKeyboard.instance.isShiftPressed &&
          evt.logicalKey.keyLabel == 'Enter') {
        if (evt is KeyDownEvent) {
          viewModel.sendPrompt(context);
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    };

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
          if (Platform.isAndroid || Platform.isIOS) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
        },
        maxLines: 10,
        minLines: 1,
        focusNode: viewModel.promptFocusNode,
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
      body: ResizableContainer(
        divider:
            const ResizableDivider(color: Colors.black, thickness: 1, size: 1),
        direction: Axis.horizontal,
        children: [
          if (isDesktop)
            ResizableChild(
                size: ResizableSize.pixels(.25.sw),
                minSize: .15.sw,
                maxSize: .35.sw,
                child: const ChatsView()),
          ResizableChild(
            child: Scaffold(
                appBar: AppBar(
                  centerTitle: !isDesktop,
                  title: const Text('Gemini Chat'),
                ),
                drawer: isDesktop
                    ? null
                    : const Drawer(
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge))
                                : ListView(
                                    reverse: true,
                                    children: [
                                      for (final item in viewModel.messageList)
                                        Column(
                                          children: [
                                            ListTile(
                                              title: const MarkdownBlock(
                                                  data: "### You"),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (item.promptImageId !=
                                                      null)
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints.loose(
                                                              Size(1.sw,
                                                                  .75.sh)),
                                                      child: kIsWeb
                                                          ? Image.memory(
                                                              viewModel
                                                                      .imageMemoryCacheForWeb[
                                                                  item.promptImageId]!,
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                            )
                                                          : Image.file(
                                                              File(p.join(
                                                                  viewModel
                                                                      .imageDir,
                                                                  item.promptImageId)),
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                            ),
                                                    ),
                                                  SelectableText(item.prompt),
                                                ],
                                              ),
                                            ),
                                            if (item.response != null)
                                              ListTile(
                                                title: const MarkdownBlock(
                                                  data: "###  Gemini",
                                                ),
                                                subtitle: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: MarkdownBlock(
                                                      data:
                                                          item.response ?? ""),
                                                ),
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
                )),
          ),
        ],
      ),
    );
  }
}
