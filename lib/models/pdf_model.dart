import 'dart:convert';

class PdfModel {
  final String id;
  final String userId;
  final String fileName;
  final String fileSize;
  final String localPath;
  final String storageUrl;
  final int pageCount;
  final int lastReadPage;
  final int lastReadPosition; // in characters or milliseconds
  final double playbackSpeed;
  final String voiceId;
  final int uploadTimestamp;
  final String topic;
  final String subject;
  final String summary;
  final List<String> keywords;
  final List<String> extractedPagesText;
  final bool isFavorite;

  PdfModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileSize,
    this.localPath = '',
    this.storageUrl = '',
    this.pageCount = 0,
    this.lastReadPage = 0,
    this.lastReadPosition = 0,
    this.playbackSpeed = 1.0,
    this.voiceId = 'en-US-Standard-A',
    required this.uploadTimestamp,
    this.topic = 'General Study',
    this.subject = 'Custom',
    this.summary = '',
    this.keywords = const [],
    this.extractedPagesText = const [],
    this.isFavorite = false,
  });

  PdfModel copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? fileSize,
    String? localPath,
    String? storageUrl,
    int? pageCount,
    int? lastReadPage,
    int? lastReadPosition,
    double? playbackSpeed,
    String? voiceId,
    int? uploadTimestamp,
    String? topic,
    String? subject,
    String? summary,
    List<String>? keywords,
    List<String>? extractedPagesText,
    bool? isFavorite,
  }) {
    return PdfModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      localPath: localPath ?? this.localPath,
      storageUrl: storageUrl ?? this.storageUrl,
      pageCount: pageCount ?? this.pageCount,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadPosition: lastReadPosition ?? this.lastReadPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      voiceId: voiceId ?? this.voiceId,
      uploadTimestamp: uploadTimestamp ?? this.uploadTimestamp,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      extractedPagesText: extractedPagesText ?? this.extractedPagesText,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileSize': fileSize,
      'localPath': localPath,
      'storageUrl': storageUrl,
      'pageCount': pageCount,
      'lastReadPage': lastReadPage,
      'lastReadPosition': lastReadPosition,
      'playbackSpeed': playbackSpeed,
      'voiceId': voiceId,
      'uploadTimestamp': uploadTimestamp,
      'topic': topic,
      'subject': subject,
      'summary': summary,
      'keywords': keywords,
      'extractedPagesText': extractedPagesText,
      'isFavorite': isFavorite ? 1 : 0, // for local db flexibility, boolean representation
    };
  }

  factory PdfModel.fromMap(Map<String, dynamic> map) {
    // Handle database conversion representing lists and booleans
    List<String> keywordsList = [];
    if (map['keywords'] != null) {
      if (map['keywords'] is String) {
        keywordsList = List<String>.from(json.decode(map['keywords']));
      } else {
        keywordsList = List<String>.from(map['keywords']);
      }
    }

    List<String> pagesList = [];
    if (map['extractedPagesText'] != null) {
      if (map['extractedPagesText'] is String) {
        pagesList = List<String>.from(json.decode(map['extractedPagesText']));
      } else {
        pagesList = List<String>.from(map['extractedPagesText']);
      }
    }

    bool favorite = false;
    if (map['isFavorite'] != null) {
      favorite = map['isFavorite'] == true || map['isFavorite'] == 1;
    }

    return PdfModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? '0 KB',
      localPath: map['localPath'] ?? '',
      storageUrl: map['storageUrl'] ?? '',
      pageCount: map['pageCount'] ?? 0,
      lastReadPage: map['lastReadPage'] ?? 0,
      lastReadPosition: map['lastReadPosition'] ?? 0,
      playbackSpeed: (map['playbackSpeed'] ?? 1.0) is int 
          ? (map['playbackSpeed'] as int).toDouble() 
          : map['playbackSpeed'] ?? 1.0,
      voiceId: map['voiceId'] ?? 'en-US-Standard-A',
      uploadTimestamp: map['uploadTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      topic: map['topic'] ?? 'General Study',
      subject: map['subject'] ?? 'Custom',
      summary: map['summary'] ?? '',
      keywords: keywordsList,
      extractedPagesText: pagesList,
      isFavorite: favorite,
    );
  }

  String toJson() => json.encode(toMap());

  factory PdfModel.fromJson(String source) => PdfModel.fromMap(json.decode(source));
}
