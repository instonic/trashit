import 'package:flutter/material.dart';
import 'trash_url_dialog.dart';

class FloatingShareButton extends StatelessWidget {
  final Function(String) onSharedUrl;

  const FloatingShareButton({
    super.key,
    required this.onSharedUrl,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showTrashUrlDialog(context: context, onSubmit: onSharedUrl),
      icon: const Icon(Icons.add),
      label: const Text('Trash It'),
      // Use floatingActionButtonTheme for consistency with theme overrides
    );
  }
}
