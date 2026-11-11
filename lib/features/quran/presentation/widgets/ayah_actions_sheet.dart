import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../bookmarks/data/bookmark_repository.dart';
import '../../domain/entities/ayah.dart';

/// E08 — Menu d'un verset (feuille du bas) :
/// - Écouter ce verset
/// - Ajouter/Retirer des signets
/// - Ajouter une note personnelle
/// - Copier
/// - Partager (texte avec nom de sourate, numéro du verset et source)
/// - Partager (carte visuelle)
/// - Tafsir (Bientôt V1.x)
class AyahActionsSheet extends ConsumerStatefulWidget {
  const AyahActionsSheet({
    super.key,
    required this.ayah,
    required this.surahTitle,
    this.onListenAyah,
  });

  final Ayah ayah;
  final String surahTitle;
  final VoidCallback? onListenAyah;

  @override
  ConsumerState<AyahActionsSheet> createState() => _AyahActionsSheetState();
}

class _AyahActionsSheetState extends ConsumerState<AyahActionsSheet> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final bool bookmarked = await ref
        .read(bookmarkRepositoryProvider)
        .isBookmarked(widget.ayah.id);
    if (mounted) {
      setState(() => _isBookmarked = bookmarked);
    }
  }

  Future<void> _toggleBookmark() async {
    final BookmarkRepository repo = ref.read(bookmarkRepositoryProvider);
    if (_isBookmarked) {
      await repo.removeBookmarkByAyahId(widget.ayah.id);
    } else {
      await repo.upsertBookmark(
        ayahId: widget.ayah.id,
        label: '${widget.surahTitle} ${widget.ayah.surahId}:${widget.ayah.ayahNumber}',
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Signet retiré (${widget.surahTitle} v.${widget.ayah.ayahNumber})'
                : 'Ajouté aux signets (${widget.surahTitle} v.${widget.ayah.ayahNumber})',
          ),
        ),
      );
    }
  }

  Future<void> _showAddNoteDialog() async {
    final TextEditingController controller = TextEditingController();
    final String? savedBody = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Note — ${widget.surahTitle} · v.${widget.ayah.ayahNumber}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Saisissez votre note personnelle (ex. « à réviser »)…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (savedBody != null && savedBody.isNotEmpty) {
      await ref.read(bookmarkRepositoryProvider).saveNote(
            ayahId: widget.ayah.id,
            body: savedBody,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note personnelle enregistrée.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedText =
        widget.ayah.formatForShare(surahTitle: widget.surahTitle);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                '${widget.surahTitle} · verset ${widget.ayah.ayahNumber}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.primaryDeepGreen),
              title: const Text('Écouter ce verset'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onListenAyah?.call();
              },
            ),
            ListTile(
              leading: Icon(
                _isBookmarked ? Icons.favorite : Icons.favorite_border,
                color: _isBookmarked ? AppColors.accentSoftGold : null,
              ),
              title: Text(
                _isBookmarked ? 'Retirer des signets' : 'Ajouter aux signets',
              ),
              onTap: _toggleBookmark,
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Ajouter une note'),
              onTap: _showAddNoteDialog,
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: formattedText));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verset copié dans le presse-papiers.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager (texte)'),
              onTap: () async {
                Navigator.of(context).pop();
                await Share.share(formattedText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Partager (carte visuelle)'),
              onTap: () {
                Navigator.of(context).pop();
                _showShareCardPreview(context);
              },
            ),
            ListTile(
              enabled: false,
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Tafsir'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'V1.x — Bientôt',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryDeepGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareCardPreview(BuildContext context) {
    final String formattedText =
        widget.ayah.formatForShare(surahTitle: widget.surahTitle);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.primaryDeepGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.ayah.displayArabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.ayah.translationText != null)
                Text(
                  widget.ayah.translationText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryLightGreen,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '${widget.surahTitle} (${widget.ayah.surahId}:${widget.ayah.ayahNumber}) · Tanzil.net',
                style: const TextStyle(
                  color: AppColors.accentSoftGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentSoftGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Share.share(formattedText);
              },
              child: const Text('Partager'),
            ),
          ],
        );
      },
    );
  }
}
