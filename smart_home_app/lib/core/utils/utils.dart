import 'package:flutter/material.dart';

Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
