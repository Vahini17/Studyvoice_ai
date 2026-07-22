import 'dart:convert';

class NoteModel {
  final String id;
  final String pdfId;
  final int pageIndex;
  final String content;
  final String colorHex;
  final int timestamp;

  NoteModel({
    required this.id,
    required this.pdfId,
    required this.pageIndex,
    required this.content,
    this.colorHex = '#FF6366F1', // Default Theme Indigo
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfId': pdfId,
      'pageIndex': pageIndex,
      'content': content,
      'colorHex': colorHex,
      'timestamp': timestamp,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      pdfId: map['pdfId'] ?? '',
      pageIndex: map['pageIndex'] ?? 0,
      content: map['content'] ?? '',
      colorHex: map['colorHex'] ?? '#FF6366F1',
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteModel.fromJson(String source) => NoteModel.fromMap(json.decode(source));
}
