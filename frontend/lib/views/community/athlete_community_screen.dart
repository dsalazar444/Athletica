import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/token_storage.dart';
import '../../models/routine/comment_model.dart';
import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/community/public_routines_view_model.dart';

class CommunityScreen extends StatefulWidget {
  final bool mineOnly;
  const CommunityScreen({super.key, this.mineOnly = false});

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  late PublicRoutinesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initViewModel(widget.mineOnly);
  }

  @override
  void didUpdateWidget(covariant CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mineOnly != widget.mineOnly) {
      _initViewModel(widget.mineOnly);
    }
  }

  void _initViewModel(bool mineOnly) {
    final repository = RoutineRepository(baseUrl: ApiConfig.baseUrl);
    _viewModel = PublicRoutinesViewModel(
      routineRepository: repository,
      mineOnly: mineOnly,
    );
    _viewModel.loadPublicRoutines();
  }

  Future<void> refresh() async {
    return _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 140;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<PublicRoutinesViewModel>(
            builder: (context, viewModel, _) {
              return RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _CommunityHeader(mineOnly: _viewModel.mineOnly),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        bottomInset,
                      ),
                      sliver: _buildBody(viewModel),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PublicRoutinesViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    if (viewModel.publicRoutines.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Todavía no hay rutinas públicas.',
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final routine = viewModel.publicRoutines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _PublicRoutineCard(
            routine: routine,
            onTapTitle: () => _showRoutineDetails(context, routine),
            viewModel: viewModel,
          ),
        );
      }, childCount: viewModel.publicRoutines.length),
    );
  }

  void _showRoutineDetails(BuildContext context, RoutineModel routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final description = routine.description.trim();
        final hasDescription = description.isNotEmpty;

        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.78),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadius.cardLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.title,
                              style: AppTextStyles.screenTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              routine.creatorName != null
                                  ? '${routine.creatorName} creó nueva rutina'
                                  : 'Creador no disponible',
                              style: AppTextStyles.sectionSubtitle.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(
                            icon: Icons.category_rounded,
                            label: routine.category,
                          ),
                          _InfoChip(
                            icon: Icons.speed_rounded,
                            label: routine.difficulty,
                          ),
                          _InfoChip(
                            icon: Icons.fitness_center_rounded,
                            label: '${routine.exercises.length} ejercicios',
                          ),
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle('Descripción'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(description, style: AppTextStyles.bodyText1),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle('Ejercicios'),
                      const SizedBox(height: AppSpacing.sm),
                      if (routine.exercises.isEmpty)
                        const _EmptyDetailBox(text: 'Sin ejercicios asignados')
                      else
                        ...routine.exercises.map(
                          (exercise) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ExerciseDetailTile(exercise: exercise),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  final bool mineOnly;
  const _CommunityHeader({this.mineOnly = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mineOnly ? 'MIS RUTINAS' : 'COMUNIDAD',
                      style: AppTextStyles.fitnessDisplay.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mineOnly ? '📋' : '🏆',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mineOnly
                      ? 'VE LOS LIKES Y COMENTARIOS DE TUS RUTINAS PÚBLICAS'
                      : 'EXPLORA RUTINAS PÚBLICAS COMPARTIDAS POR OTROS USUARIOS',
                  style: AppTextStyles.fitnessCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicRoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onTapTitle;
  final PublicRoutinesViewModel viewModel;

  const _PublicRoutineCard({
    required this.routine,
    required this.onTapTitle,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final creatorName = (routine.creatorName?.isNotEmpty ?? false)
        ? routine.creatorName!
        : 'Usuario';
    final initials = PublicRoutinesViewModel.getInitials(creatorName);
    final isOwnPost = viewModel.isOwnRoutine(routine);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AuthorAvatar(initials: initials),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creatorName, style: AppTextStyles.bodyText1),
                    Text('creó nueva rutina', style: AppTextStyles.bentoUnit),
                  ],
                ),
              ),
              if (!isOwnPost) ...[
                const SizedBox(width: AppSpacing.md),
                _FollowButton(
                  isFollowing: routine.isFollowing ?? false,
                  onFollow: () => viewModel.followCreator(routine.createdBy!),
                  onUnfollow: () =>
                      viewModel.unfollowCreator(routine.createdBy!),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onTapTitle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.28),
                    AppColors.primaryLight.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      routine.title,
                      style: AppTextStyles.bodyText1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SocialBar(routine: routine, viewModel: viewModel),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AUTHOR AVATAR
// ─────────────────────────────────────────────
class _AuthorAvatar extends StatelessWidget {
  final String initials;

  const _AuthorAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.tagBackground,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bentoUnit.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bentoUnit),
        ],
      ),
    );
  }
}

class _EmptyDetailBox extends StatelessWidget {
  final String text;

  const _EmptyDetailBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.bodyText1),
    );
  }
}

class _ExerciseDetailTile extends StatelessWidget {
  final dynamic exercise;

  const _ExerciseDetailTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.tagBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${exercise.order}',
                style: AppTextStyles.bentoUnit.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(exercise.exercise.name, style: AppTextStyles.bodyText1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SOCIAL BAR (likes + comments)
// ─────────────────────────────────────────────
class _SocialBar extends StatelessWidget {
  final RoutineModel routine;
  final PublicRoutinesViewModel viewModel;

  const _SocialBar({required this.routine, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LikeButton(routine: routine, viewModel: viewModel),
        const SizedBox(width: AppSpacing.md),
        _CommentButton(routine: routine, viewModel: viewModel),
      ],
    );
  }
}

class _LikeButton extends StatelessWidget {
  final RoutineModel routine;
  final PublicRoutinesViewModel viewModel;

  const _LikeButton({required this.routine, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => viewModel.toggleRoutineReaction(routine.id!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            routine.userLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: routine.userLiked
                ? Colors.redAccent
                : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 5),
          Text(
            '${routine.likesCount}',
            style: AppTextStyles.bentoUnit.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentButton extends StatelessWidget {
  final RoutineModel routine;
  final PublicRoutinesViewModel viewModel;

  const _CommentButton({required this.routine, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        viewModel.loadComments(routine.id!);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ChangeNotifierProvider.value(
            value: viewModel,
            child: _CommentsSheet(routine: routine),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 5),
          Text(
            '${routine.commentsCount}',
            style: AppTextStyles.bentoUnit.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COMMENTS SHEET
// ─────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final RoutineModel routine;
  const _CommentsSheet({required this.routine});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  int? _replyToId;
  String? _replyToUsername;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    TokenStorage.getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setReply(int commentId, String username) {
    setState(() {
      _replyToId = commentId;
      _replyToUsername = username;
    });
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
      _replyToUsername = null;
    });
  }

  Future<void> _send(PublicRoutinesViewModel vm) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final parentId = _replyToId;
    _clearReply();
    try {
      await vm.postComment(widget.routine.id!, text, parentId: parentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al comentar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicRoutinesViewModel>(
      builder: (context, vm, _) {
        final routineId = widget.routine.id!;
        final isLoading = vm.commentsLoadingMap[routineId] ?? false;
        final comments = vm.commentsMap[routineId] ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Comentarios',
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${comments.length}',
                        style: AppTextStyles.bentoUnit.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : comments.isEmpty
                      ? Center(
                          child: Text(
                            'Sé el primero en comentar.',
                            style: AppTextStyles.bentoUnit.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: comments.length,
                          itemBuilder: (_, i) => _CommentTile(
                            comment: comments[i],
                            routineId: routineId,
                            currentUserId: _currentUserId,
                            viewModel: vm,
                            onReply: _setReply,
                            isReply: false,
                          ),
                        ),
                ),
                const Divider(height: 1),
                if (_replyToUsername != null)
                  Container(
                    color: AppColors.tagBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Respondiendo a @$_replyToUsername',
                          style: AppTextStyles.bentoUnit.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _clearReply,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            hintStyle: AppTextStyles.bentoUnit.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => _send(vm),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final int routineId;
  final int? currentUserId;
  final PublicRoutinesViewModel viewModel;
  final void Function(int commentId, String username) onReply;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    required this.routineId,
    required this.currentUserId,
    required this.viewModel,
    required this.onReply,
    required this.isReply,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundColor: AppColors.tagBackground,
                child: Text(
                  comment.username.isNotEmpty
                      ? comment.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: isReply ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: AppTextStyles.bentoUnit.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: AppTextStyles.bentoUnit.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(comment.text, style: AppTextStyles.bodyText1),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => viewModel.toggleCommentReaction(
                            comment.id,
                            routineId,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                comment.userLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: comment.userLiked
                                    ? Colors.redAccent
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: AppTextStyles.bentoUnit.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isReply) ...[
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () => onReply(comment.id, comment.username),
                            child: Text(
                              'Responder',
                              style: AppTextStyles.bentoUnit.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (comment.userId == currentUserId)
                          GestureDetector(
                            onTap: () =>
                                viewModel.deleteComment(comment.id, routineId),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => _CommentTile(
                comment: reply,
                routineId: routineId,
                currentUserId: currentUserId,
                viewModel: viewModel,
                onReply: onReply,
                isReply: true,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FOLLOW BUTTON
// ─────────────────────────────────────────────
class _FollowButton extends StatefulWidget {
  final bool isFollowing;
  final Future<void> Function() onFollow;
  final Future<void> Function() onUnfollow;

  const _FollowButton({
    required this.isFollowing,
    required this.onFollow,
    required this.onUnfollow,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isLoading = false;

  Future<void> _handleFollowTap() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isFollowing) {
        await widget.onUnfollow();
      } else {
        await widget.onFollow();
      }
    } catch (e) {
      // Error se maneja en el ViewModel
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleFollowTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.75)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isFollowing
                        ? Icons.person_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isFollowing ? 'Siguiendo' : 'Seguir',
                    style: AppTextStyles.bentoUnit.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
