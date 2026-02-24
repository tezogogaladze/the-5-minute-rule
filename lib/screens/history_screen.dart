import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../services/timer_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final sessions = storage.getSessions();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (56 px — identical structure to HomeScreen) ──────────
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Text(
                      AppStrings.historyTitle,
                      style: AppTextStyles.heading,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.secondaryText,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            if (sessions.isEmpty)
              Expanded(child: _EmptyState())
            else ...[
              // ── Stats bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: _StatsBar(sessions: sessions),
              ),

              const SizedBox(height: 28),

              // ── Divider ───────────────────────────────────────────────────
              const Divider(color: AppColors.divider, height: 1, thickness: 1),

              const SizedBox(height: 8),

              // ── Session list ──────────────────────────────────────────────
              Expanded(
                child: _SessionList(sessions: sessions),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<Session> sessions;

  const _StatsBar({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalStarts = sessions.length;
    final avgSeconds =
        sessions.map((s) => s.durationSeconds).reduce((a, b) => a + b) ~/
            sessions.length;
    final longestSeconds =
        sessions.map((s) => s.durationSeconds).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        _StatCell(
          value: '$totalStarts',
          label: AppStrings.totalStarts.toUpperCase(),
        ),
        _StatDivider(),
        _StatCell(
          value: TimerController.formatSeconds(avgSeconds),
          label: AppStrings.averageTime.toUpperCase(),
        ),
        _StatDivider(),
        _StatCell(
          value: TimerController.formatSeconds(longestSeconds),
          label: AppStrings.longestTime.toUpperCase(),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// ── Session list ──────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  final List<Session> sessions;

  const _SessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final longestSeconds = sessions
        .map((s) => s.durationSeconds)
        .reduce((a, b) => a > b ? a : b);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionItem(
          session: session,
          longestSeconds: longestSeconds,
        );
      },
    );
  }
}

class _SessionItem extends StatelessWidget {
  final Session session;
  final int longestSeconds;

  const _SessionItem({
    required this.session,
    required this.longestSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = longestSeconds > 0
        ? session.durationSeconds / longestSeconds
        : 0.0;
    final durationText =
        TimerController.formatSeconds(session.durationSeconds);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task name + duration
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  session.taskName,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryText,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                durationText,
                style: AppTextStyles.body.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Track
                  Container(
                    height: 2,
                    width: constraints.maxWidth,
                    color: AppColors.divider,
                  ),
                  // Fill
                  Container(
                    height: 2,
                    width: constraints.maxWidth * progress,
                    color: AppColors.secondaryText,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        AppStrings.emptyHistory,
        style: AppTextStyles.subheading,
        textAlign: TextAlign.center,
      ),
    );
  }
}
