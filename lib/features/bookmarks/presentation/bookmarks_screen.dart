import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';
import '../../../l10n/app_localizations.dart';
import '../data/bookmark_repository.dart';
import '../domain/entities/bookmark_item.dart';

/// E14 — Signets, Notes personnelles et Historique de lecture :
/// - 3 onglets : `[Signets][Notes][Historique]`.
/// - Glisser vers la gauche pour supprimer, vers la droite pour modifier la note.
/// - État vide : message sobre et bouton « Ouvrir le Coran ».
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() => _refreshTick++);
    }
  }

  Future<void> _editNoteDialog(int ayahId, String initialBody) async {
    final TextEditingController controller =
        TextEditingController(text: initialBody);
    final String? updated = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Modifier la note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Votre note personnelle…',
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
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      await ref.read(bookmarkRepositoryProvider).saveNote(
            ayahId: ayahId,
            body: updated,
          );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: buildRoyalAppBar(
        title: l10n.tabBookmarks,
        subtitle: '${l10n.bookmarks} · ${l10n.notes} · ${l10n.history}',
        actions: <Widget>[
          IconButton(
            tooltip: 'Rechercher (E10)',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
        bottom: buildRoyalTabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: l10n.bookmarks),
            Tab(text: l10n.notes),
            Tab(text: l10n.history),
          ],
        ),
      ),
      body: TabBarView(
        key: ValueKey<int>(_refreshTick),
        controller: _tabController,
        children: <Widget>[
          _buildBookmarksTab(context, l10n),
          _buildNotesTab(context, l10n),
          _buildHistoryTab(context, l10n),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: MushafFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 68,
                height: 68,
                child: CustomPaint(
                  painter: IslamicStarPainter(),
                  child: Center(
                    child: Icon(
                      Icons.bookmark_border,
                      size: 30,
                      color: AppColors.emeraldNight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.emptyBookmarks,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.quranList),
                icon: const Icon(
                  Icons.menu_book,
                  color: AppColors.goldLight,
                ),
                label: Text(l10n.openQuran),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<BookmarkItem>>(
      future: ref.read(bookmarkRepositoryProvider).getAllBookmarks(),
      builder: (BuildContext context, AsyncSnapshot<List<BookmarkItem>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<BookmarkItem> items = snap.data ?? const <BookmarkItem>[];
        if (items.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            final BookmarkItem item = items[index];
            final String title = item.ayah != null
                ? '${item.ayah!.surahNameTranslit ?? "Sourate ${item.ayah!.surahId}"} ${item.ayah!.surahId}:${item.ayah!.ayahNumber}'
                : (item.label ?? 'Verset #${item.ayahId}');

            return Dismissible(
              key: ValueKey<String>('bm_${item.id}'),
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.edit_note, color: Colors.white),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (DismissDirection direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _editNoteDialog(item.ayahId, item.label ?? '');
                  return false;
                }
                return true;
              },
              onDismissed: (_) async {
                await ref
                    .read(bookmarkRepositoryProvider)
                    .removeBookmarkByAyahId(item.ayahId);
                _reload();
              },
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.favorite,
                    color: AppColors.accentSoftGold,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.ayah?.translationText ?? item.label ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    if (item.ayah != null) {
                      await context.push(
                        AppRoutes.ayahReaderPath(
                          item.ayah!.surahId,
                          initialAyah: item.ayah!.ayahNumber,
                        ),
                      );
                      _reload();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotesTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<NoteItem>>(
      future: ref.read(bookmarkRepositoryProvider).getAllNotes(),
      builder: (BuildContext context, AsyncSnapshot<List<NoteItem>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<NoteItem> notes = snap.data ?? const <NoteItem>[];
        if (notes.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (BuildContext context, int index) {
            final NoteItem note = notes[index];
            final String title = note.ayah != null
                ? '${note.ayah!.surahNameTranslit ?? "Sourate ${note.ayah!.surahId}"} ${note.ayah!.surahId}:${note.ayah!.ayahNumber}'
                : 'Verset #${note.ayahId}';

            return Dismissible(
              key: ValueKey<String>('note_${note.id}'),
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (DismissDirection direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _editNoteDialog(note.ayahId, note.body);
                  return false;
                }
                return true;
              },
              onDismissed: (_) async {
                await ref.read(bookmarkRepositoryProvider).deleteNote(note.id);
                _reload();
              },
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.sticky_note_2_outlined,
                    color: AppColors.primaryDeepGreen,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Note : « ${note.body} »'),
                  onTap: () async {
                    if (note.ayah != null) {
                      await context.push(
                        AppRoutes.ayahReaderPath(
                          note.ayah!.surahId,
                          initialAyah: note.ayah!.ayahNumber,
                        ),
                      );
                      _reload();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<ReadingHistoryItem>>(
      future: ref.read(bookmarkRepositoryProvider).getRecentHistory(),
      builder:
          (BuildContext context, AsyncSnapshot<List<ReadingHistoryItem>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<ReadingHistoryItem> history =
            snap.data ?? const <ReadingHistoryItem>[];
        if (history.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (BuildContext context, int index) {
            final ReadingHistoryItem entry = history[index];
            final String title = entry.ayah != null
                ? '${entry.ayah!.surahNameTranslit ?? "Sourate ${entry.ayah!.surahId}"} · v.${entry.ayah!.ayahNumber}'
                : 'Verset #${entry.ayahId}';
            return Card(
              child: ListTile(
                leading: IslamicStarBadge(
                  label: '${entry.ayah?.surahId ?? 1}',
                  size: 42,
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Page ${entry.ayah?.page15 ?? 1} · Mode ${entry.mode}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (entry.ayah != null) {
                    await context.push(
                      AppRoutes.ayahReaderPath(
                        entry.ayah!.surahId,
                        initialAyah: entry.ayah!.ayahNumber,
                      ),
                    );
                    _reload();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
