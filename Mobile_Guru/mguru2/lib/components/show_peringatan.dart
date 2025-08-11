import 'dart:ui';

import 'package:flutter/material.dart';

class ShowPeringatan extends StatelessWidget {
  final String text;
  final String title;
  const ShowPeringatan({
    Key? key,
    required this.text,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(text),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Keluar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
