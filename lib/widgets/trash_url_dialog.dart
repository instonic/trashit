import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showTrashUrlDialog({
  required BuildContext context,
  required void Function(String url) onSubmit,
}) async {
  final TextEditingController urlController = TextEditingController();

  // Prefill from clipboard if it contains a valid URL
  bool prefilledFromClipboard = false;
  try {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty && _isValidUrl(text)) {
      urlController.text = text;
      prefilledFromClipboard = true;
    }
  } catch (_) {
    // Ignore clipboard errors
  }

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Trash Content'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Paste a URL to trash some content!',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    urlController.text = data!.text!.trim();
                  }
                },
              ),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final url = value.trim();
              if (url.isNotEmpty && _isValidUrl(url)) {
                Navigator.of(context).pop();
                onSubmit(url);
              }
            },
          ),
          if (prefilledFromClipboard) ...[
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.content_paste, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detected link from clipboard',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final url = urlController.text.trim();
            if (url.isNotEmpty && _isValidUrl(url)) {
              Navigator.of(context).pop();
              onSubmit(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid URL'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('Trash It!'),
        ),
      ],
    ),
  );
}

bool _isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  } catch (e) {
    return false;
  }
}
