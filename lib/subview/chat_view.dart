import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gemeini_chat/subview/image_view.dart';
import 'package:gemeini_chat/view/geminin_chat_view.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:path/path.dart' as p;

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(geminiChatViewModelProvider);
    return Expanded(
        child: viewModel.imageFile != null
            ? const ImageView()
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
  }
}
