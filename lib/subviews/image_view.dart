import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_chat/views/chat_view.dart';

class ImageView extends ConsumerWidget {
  const ImageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(chatViewModelProvider);
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: kIsWeb
                ? Image.network(
                    viewModel.imageFile!.path,
                    fit: BoxFit.contain,
                  )
                : Image.file(
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
    );
  }
}
