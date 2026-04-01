import 'package:flutter/material.dart';

class CreateChannelScreen extends StatelessWidget {
  const CreateChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Channel')),
      body: const Center(child: Text('Form to create channel')),
    );
  }
}
