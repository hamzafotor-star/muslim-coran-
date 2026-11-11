import 'package:flutter/foundation.dart';
import '../../../quran/domain/entities/ayah.dart';

@immutable
class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.ayahId,
    required this.createdAt,
    this.label,
    this.color,
    this.ayah,
  });

  final int id;
  final int ayahId;
  final String? label;
  final String? color;
  final int createdAt;
  final Ayah? ayah;
}

@immutable
class NoteItem {
  const NoteItem({
    required this.id,
    required this.ayahId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.ayah,
  });

  final int id;
  final int ayahId;
  final String body;
  final int createdAt;
  final int updatedAt;
  final Ayah? ayah;
}

@immutable
class ReadingHistoryItem {
  const ReadingHistoryItem({
    required this.id,
    required this.ayahId,
    required this.mode,
    required this.readAt,
    this.ayah,
  });

  final int id;
  final int ayahId;
  final String mode;
  final int readAt;
  final Ayah? ayah;
}
