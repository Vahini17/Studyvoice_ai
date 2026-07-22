import 'package:flutter_test/flutter_test.dart';
import 'package:study_voice_ai/models/note_model.dart';

void main() {
  test('NoteModel creation test', () {
    final note = NoteModel(
      id: '1',
      pdfId: 'pdf_123',
      pageIndex: 5,
      content: 'This is a test note',
      timestamp: 1689999000000,
    );

    expect(note.id, '1');
    expect(note.pdfId, 'pdf_123');
    expect(note.pageIndex, 5);
    expect(note.content, 'This is a test note');
    expect(note.timestamp, 1689999000000);
  });
}

