import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'dart:convert';

class Channel {
  final String id;
  final String name;
  final String description;
  final bool isReadOnly;

  Channel({required this.id, required this.name, required this.description, required this.isReadOnly});

  factory Channel.fromMap(Map<String, dynamic> map, String id) {
    return Channel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isReadOnly: map['isReadOnly'] ?? false,
    );
  }
}

class ChannelMessage {
  final String id;
  final String text;
  final String senderName;
  final String senderFlat;
  final String senderId;
  final DateTime createdAt;

  ChannelMessage({required this.id, required this.text, required this.senderName, required this.senderFlat, required this.senderId, required this.createdAt});

  factory ChannelMessage.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ChannelMessage(
      id: doc.id,
      text: map['text'] ?? '',
      senderName: map['senderName'] ?? '',
      senderFlat: map['senderFlat'] ?? '',
      senderId: map['senderId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final channelsListProvider = FutureProvider<List<Channel>>((ref) async {
  final res = await ApiService.get('/channels');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['channels'] as List).map((e) => Channel.fromMap(e, e['id'])).toList();
  } else {
    throw Exception(jsonDecode(res.body)['error'] ?? 'Failed to load channels');
  }
});

final channelMessagesProvider = StreamProvider.family<List<ChannelMessage>, String>((ref, channelId) {
  return FirebaseFirestore.instance
      .collection('channels')
      .doc(channelId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ChannelMessage.fromDoc(doc)).toList());
});
