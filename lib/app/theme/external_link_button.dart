import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

class ExternalLinkButton extends StatelessWidget {
  const ExternalLinkButton(
      {super.key, required this.label, required this.url, this.opener});
  final String label;
  final Uri url;
  final ExternalLinkOpener? opener;

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await (opener?.call(url) ??
          launchUrl(url, webOnlyWindowName: '_blank'));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open the link. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label, textAlign: TextAlign.center),
      );
}
