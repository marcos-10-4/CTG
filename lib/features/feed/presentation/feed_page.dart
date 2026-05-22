import 'package:ctg_app/core/theme/app_colors.dart';
import 'package:ctg_app/core/theme/app_text_styles.dart';
import 'package:ctg_app/features/auth/application/auth_notifier.dart';
import 'package:ctg_app/features/feed/application/feed_notifier.dart';
import 'package:ctg_app/features/feed/domain/entities/club_post.dart';
import 'package:ctg_app/features/feed/presentation/widgets/post_card.dart';
import 'package:ctg_app/shared/widgets/app_avatar.dart';
import 'package:ctg_app/shared/widgets/filter_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(feedFilterNotifierProvider);
    final postsAsync = ref.watch(feedPostsProvider(filter: filter));
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMM', 'es').format(DateTime.now()).toUpperCase(),
                  style: AppTextStyles.monoSm,
                ),
                Text('Feed', style: AppTextStyles.headingLg),
              ],
            ),
            actions: [
              // Notification bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.ink,
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // Avatar
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: userAsync.whenData(
                    (user) => AppAvatar(
                      name: user?.displayName ?? 'U',
                      photoUrl: user?.photoUrl,
                      size: 32,
                    ),
                  ).value ?? const SizedBox.square(dimension: 32),
                ),
              ),
            ],
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FilterChipBar<PostKind?>(
                selected: filter,
                onSelected: ref.read(feedFilterNotifierProvider.notifier).setFilter,
                items: const [
                  (value: null, label: 'Todo'),
                  (value: PostKind.news, label: 'Noticias'),
                  (value: PostKind.tournament, label: 'Torneos'),
                  (value: PostKind.photo, label: 'Fotos'),
                  (value: PostKind.announcement, label: 'Avisos'),
                ],
              ),
            ),
          ),

          // Posts
          postsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(e.toString())),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hay publicaciones',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(
                  post: posts[i],
                  onTap: () => context.push('/feed/post/${posts[i].id}'),
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: userAsync.whenData((user) {
        if (user?.role.name == 'admin') {
          return FloatingActionButton(
            onPressed: () => _showCreateSheet(context, ref, user!.id),
            child: const Icon(Icons.add),
          );
        }
        return null;
      }).value,
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref, String authorId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreatePostSheet(authorId: authorId),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet({required this.authorId});
  final String authorId;

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  PostKind _kind = PostKind.news;
  bool _pinned = false;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final post = ClubPost(
      id: const Uuid().v4(),
      authorId: widget.authorId,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      kind: _kind,
      likesCount: 0,
      commentsCount: 0,
      pinned: _pinned,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(feedRepositoryProvider).createPost(post);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nueva publicación'),
              const SizedBox(height: 16),
              DropdownButtonFormField<PostKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: PostKind.news,
                    child: Text('Noticia'),
                  ),
                  DropdownMenuItem(
                    value: PostKind.announcement,
                    child: Text('Aviso'),
                  ),
                  DropdownMenuItem(
                    value: PostKind.tournament,
                    child: Text('Torneo'),
                  ),
                  DropdownMenuItem(
                    value: PostKind.photo,
                    child: Text('Foto'),
                  ),
                ],
                onChanged: (v) => setState(() => _kind = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: 'Contenido *'),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fijar en el feed'),
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,),
                        )
                      : const Text('Publicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
