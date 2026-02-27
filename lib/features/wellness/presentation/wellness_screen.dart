import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// Parent Wellness Screen — mood tracker, affirmations,
/// self-care tips, breathing exercises, and support resources.
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  int? _selectedMood;
  bool _isBreathing = false;
  String _breathLabel = 'Start';
  Timer? _breathTimer;
  int _breathCycle = 0;

  static const _moodKey = 'wellness_mood';
  static const _moodDateKey = 'wellness_mood_date';

  // ─── Mood Emojis ──────────────────────────────────────────
  static const _moods = [
    {'emoji': '😊', 'label': 'Great'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😟', 'label': 'Low'},
    {'emoji': '😫', 'label': 'Tough'},
  ];

  // ─── Affirmations ─────────────────────────────────────────
  static const _affirmations = [
    'You are doing an incredible job as a parent. Every small step counts.',
    'Your patience and love are making a real difference in your child\'s life.',
    'It\'s okay to have hard days. You are stronger than you think.',
    'You don\'t have to be perfect — you just have to be present.',
    'Taking care of yourself IS taking care of your child.',
    'Progress isn\'t always visible, but it\'s always happening.',
    'You are exactly the parent your child needs.',
    'Celebrate every tiny victory — they add up to something beautiful.',
  ];

  // ─── Self-Care Tips ───────────────────────────────────────
  static const _selfCareTips = [
    {
      'icon': Icons.bedtime_rounded,
      'title': 'Prioritize Sleep',
      'tip': 'Even 15 extra minutes of sleep can improve your patience and energy. Try a consistent bedtime routine for yourself.',
      'color': Color(0xFF6366F1),
    },
    {
      'icon': Icons.directions_walk_rounded,
      'title': 'Move Your Body',
      'tip': 'A short 10-minute walk can reduce stress hormones. Walk with your child or take a solo break outdoors.',
      'color': Color(0xFF10B981),
    },
    {
      'icon': Icons.people_rounded,
      'title': 'Stay Connected',
      'tip': 'Reach out to a friend, join a support group, or chat with other parents. You are not alone in this journey.',
      'color': Color(0xFFF59E0B),
    },
    {
      'icon': Icons.spa_rounded,
      'title': 'Daily Pause',
      'tip': 'Take 5 minutes to sit quietly, breathe deeply, or enjoy a cup of tea. Small pauses recharge your emotional battery.',
      'color': Color(0xFFEC4899),
    },
    {
      'icon': Icons.auto_stories_rounded,
      'title': 'Journal It Out',
      'tip': 'Write down one good thing from today and one challenge. Journaling helps process emotions and track progress.',
      'color': Color(0xFF8B5CF6),
    },
    {
      'icon': Icons.music_note_rounded,
      'title': 'Music Therapy',
      'tip': 'Put on your favorite song during a stressful moment. Music activates calming brain circuits in seconds.',
      'color': Color(0xFF06B6D4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_moodDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == today) {
      setState(() => _selectedMood = prefs.getInt(_moodKey));
    }
  }

  Future<void> _saveMood(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt(_moodKey, index);
    await prefs.setString(_moodDateKey, today);
    setState(() => _selectedMood = index);
  }

  void _startBreathingExercise() {
    if (_isBreathing) {
      _breathTimer?.cancel();
      setState(() {
        _isBreathing = false;
        _breathLabel = 'Start';
        _breathCycle = 0;
      });
      return;
    }

    setState(() {
      _isBreathing = true;
      _breathCycle = 0;
    });

    _runBreathCycle();
  }

  void _runBreathCycle() {
    if (_breathCycle >= 5) {
      setState(() {
        _isBreathing = false;
        _breathLabel = 'Done! 🎉';
        _breathCycle = 0;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _breathLabel = 'Start');
      });
      return;
    }

    // Breathe In (4s)
    setState(() => _breathLabel = 'Breathe In...');
    _breathTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Hold (4s)
      setState(() => _breathLabel = 'Hold...');
      _breathTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        // Breathe Out (4s)
        setState(() => _breathLabel = 'Breathe Out...');
        _breathTimer = Timer(const Duration(seconds: 4), () {
          if (!mounted) return;
          setState(() => _breathCycle++);
          _runBreathCycle();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final affirmation = _affirmations[
        DateTime.now().day % _affirmations.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Wellness')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Mood Check-In ──────────────────────────
            _buildMoodCheckIn(context, isDark),
            const SizedBox(height: 24),

            // ─── Daily Affirmation ──────────────────────
            _buildAffirmation(context, isDark, affirmation),
            const SizedBox(height: 24),

            // ─── Breathing Exercise ─────────────────────
            _buildBreathingExercise(context, isDark),
            const SizedBox(height: 24),

            // ─── Self-Care Tips ─────────────────────────
            _sectionTitle(context, 'Self-Care Tips'),
            const SizedBox(height: 12),
            _buildSelfCareTips(context, isDark),
            const SizedBox(height: 24),

            // ─── Support Resources ──────────────────────
            _sectionTitle(context, 'Support Resources'),
            const SizedBox(height: 12),
            _buildResources(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═════════════════════════════════════════════════════════
  // MOOD CHECK-IN
  // ═════════════════════════════════════════════════════════
  Widget _buildMoodCheckIn(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6EF5), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B6EF5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.asMap().entries.map((entry) {
              final index = entry.key;
              final mood = entry.value;
              final isSelected = _selectedMood == index;
              return GestureDetector(
                onTap: () => _saveMood(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood['emoji']!,
                        style: TextStyle(fontSize: isSelected ? 30 : 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood['label']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedMood != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _selectedMood! <= 1
                    ? '💙 Wonderful! Keep up the positive energy!'
                    : _selectedMood == 2
                        ? '💙 That\'s perfectly okay. You\'re doing great.'
                        : '💙 Remember: tough days don\'t last, but tough parents do.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(
          begin: 0.05,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ═════════════════════════════════════════════════════════
  // DAILY AFFIRMATION
  // ═════════════════════════════════════════════════════════
  Widget _buildAffirmation(
      BuildContext context, bool isDark, String affirmation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2140), const Color(0xFF2D3154)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            affirmation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: affirmation));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Affirmation copied! 💛'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy & Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  // ═════════════════════════════════════════════════════════
  // BREATHING EXERCISE
  // ═════════════════════════════════════════════════════════
  Widget _buildBreathingExercise(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBackground
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3))
            : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.air_rounded,
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '4-4-4 Breathing',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      '5 cycles • Reduces stress in 60 seconds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Breathing circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: _isBreathing
                ? (_breathLabel.contains('In') ? 120 : 80)
                : 100,
            height: _isBreathing
                ? (_breathLabel.contains('In') ? 120 : 80)
                : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(
                      alpha: _isBreathing ? 0.6 : 0.2),
                  AppColors.primary.withValues(
                      alpha: _isBreathing ? 0.4 : 0.1),
                ],
              ),
              boxShadow: _isBreathing
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                _breathLabel,
                style: TextStyle(
                  color: _isBreathing
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                  fontSize: _isBreathing ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          if (_isBreathing) ...[
            const SizedBox(height: 10),
            Text(
              'Cycle ${_breathCycle + 1} of 5',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startBreathingExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isBreathing ? AppColors.error : AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _isBreathing ? 'Stop' : 'Begin Breathing Exercise',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  // ═════════════════════════════════════════════════════════
  // SELF-CARE TIPS CAROUSEL
  // ═════════════════════════════════════════════════════════
  Widget _buildSelfCareTips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selfCareTips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tip = _selfCareTips[index];
          final color = tip['color'] as Color;
          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tip['icon'] as IconData,
                      color: color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  tip['title'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    tip['tip'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.4,
                        ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 400.ms,
              );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // SUPPORT RESOURCES
  // ═════════════════════════════════════════════════════════
  Widget _buildResources(BuildContext context, bool isDark) {
    final resources = [
      {
        'icon': Icons.phone_rounded,
        'title': 'Crisis Helpline',
        'info': '988 Suicide & Crisis Lifeline',
        'detail': 'Call or text 988 • Available 24/7',
        'color': AppColors.error,
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Parent Support Groups',
        'info': 'Parent to Parent USA',
        'detail': 'p2pusa.org • Connect with other parents',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.psychology_rounded,
        'title': 'Caregiver Mental Health',
        'info': 'NAMI Family Support',
        'detail': 'nami.org • Free family programs',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.child_care_rounded,
        'title': 'Disability Resources',
        'info': 'Family Voices',
        'detail': 'familyvoices.org • Advocacy & support',
        'color': AppColors.purple,
      },
    ];

    return Column(
      children: resources.asMap().entries.map((entry) {
        final index = entry.key;
        final resource = entry.value;
        final color = resource['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(resource['icon'] as IconData,
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'] as String,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    Text(
                      resource['info'] as String,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                    Text(
                      resource['detail'] as String,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 400.ms,
            );
      }).toList(),
    );
  }
}
