import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../services/cache/smart_data_repository.dart';
import '../../../models/post_model.dart';
import '../../../widgets/custom_button.dart';

/// Community Resources & Parent Forum Screen
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SmartDataRepository _repository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = context.read<SmartDataRepository>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePostDialog() {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share an Encouraging Note',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'What\'s on your mind? Share a win, a tip, or just say hello to other parents...',
                      filled: true,
                      fillColor:
                          isDark
                              ? AppColors.darkCardBackground
                              : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Post to Community',
                    onPressed: () async {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context);
                        final user = await _repository.getUserProfile(
                          _repository.currentUserId ?? '',
                        );
                        await _repository.createPost(
                          text,
                          user?.displayName ?? 'Anonymous Parent',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Parent Forum'), Tab(text: 'Resources')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildForumTab(isDark), _buildResourcesTab(isDark)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text(
          'Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildForumTab(bool isDark) {
    return StreamBuilder<List<PostModel>>(
      stream: _repository.getCommunityPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts: \${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!;

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_rounded,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet.\nBe the first to share an encouraging note!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final isLiked = post.likes.contains(
              _repository.currentUserId,
            );

            return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkCardBackground
                            : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? [] : AppShadows.subtle,
                    border:
                        isDark
                            ? Border.all(
                              color: AppColors.darkBorder.withValues(
                                alpha: 0.3,
                              ),
                            )
                            : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(
                                    post.createdAt,
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
                                onTap:
                                    () => _repository.toggleLikePost(
                                      post.id!,
                                    ),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color:
                                            isLiked
                                                ? Colors.red
                                                : AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '\${post.likes.length}',
                                        style: TextStyle(
                                          color:
                                              isLiked
                                                  ? Colors.red
                                                  : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate(target: isLiked ? 1 : 0)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 200.ms,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.2, 1.2),
                                end: const Offset(1, 1),
                              ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 50 * index))
                .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
          },
        );
      },
    );
  }

  Widget _buildResourcesTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 24),
          _buildCategory(
            context,
            isDark,
            title: 'Autism Spectrum (ASD)',
            icon: Icons.emoji_people_rounded,
            color: AppColors.primary,
            resources: [
              const _Resource(
                'Autism Speaks Community',
                'autismspeaks.org',
                'Connect with families, share stories, find local events',
              ),
              const _Resource(
                'r/Autism Parenting (Reddit)',
                'reddit.com/r/AutismParenting',
                'Active online community of parents sharing daily experiences',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategory(
            context,
            isDark,
            title: 'ADHD & Attention',
            icon: Icons.psychology_rounded,
            color: AppColors.accent,
            resources: [
              const _Resource(
                'CHADD',
                'chadd.org',
                'National resource on ADHD with parent support groups',
              ),
              const _Resource(
                'ADDitude Magazine Community',
                'additudemag.com',
                'Expert advice, webinars, and support forums',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategory(
            context,
            isDark,
            title: 'General Parenting Support',
            icon: Icons.groups_rounded,
            color: AppColors.purple,
            resources: [
              const _Resource(
                'Parent to Parent USA',
                'p2pusa.org',
                'Nationwide network of parent-to-parent support',
              ),
              const _Resource(
                'Family Voices',
                'familyvoices.org',
                'Advocacy for families of children with special needs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF5B6EF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.people_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text(
                'You Are Not Alone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find local support groups and access resources from organizations that understand your journey.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildCategory(
    BuildContext context,
    bool isDark, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_Resource> resources,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 10),
        ...resources.asMap().entries.map((entry) {
          final res = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border:
                  isDark
                      ? Border.all(
                        color: AppColors.darkBorder.withValues(alpha: 0.2),
                      )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  res.url,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  res.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 80 * entry.key),
            duration: 300.ms,
          );
        }),
      ],
    );
  }
}

class _Resource {
  final String name;
  final String url;
  final String description;
  const _Resource(this.name, this.url, this.description);
}
