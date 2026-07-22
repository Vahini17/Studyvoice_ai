import 'dart:convert';

class BookmarkModel {
  final String id;
  final String pdfId;
  final int pageIndex;
  final int textPosition;
  final String noteText;
  final int timestamp;

  BookmarkModel({
    required this.id,
    required this.pdfId,
    required this.pageIndex,
    required this.textPosition,
    this.noteText = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfId': pdfId,
      'pageIndex': pageIndex,
      'textPosition': textPosition,
      'noteText': noteText,
      'timestamp': timestamp,
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] ?? '',
      pdfId: map['pdfId'] ?? '',
      pageIndex: map['pageIndex'] ?? 0,
      textPosition: map['textPosition'] ?? 0,
      noteText: map['noteText'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String toJson() => json.encode(toMap());

  factory BookmarkModel.fromJson(String source) => BookmarkModel.fromMap(json.decode(source));
}
