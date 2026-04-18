import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft pulsing placeholder (no extra packages).
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = (math.sin(_c.value * math.pi) + 1) / 2;
        final a = 0.22 + 0.18 * t;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: a),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// Matches [_AssetTile] layout on the home screen.
class HomeAssetTileSkeleton extends StatelessWidget {
  const HomeAssetTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonPulse(
                  width: 44,
                  height: 44,
                  borderRadius:
                      BorderRadius.all(Radius.circular(22))),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonPulse(
                        width: 120,
                        height: 14,
                        borderRadius:
                            BorderRadius.all(Radius.circular(6))),
                    SizedBox(height: 8),
                    SkeletonPulse(
                        width: 90,
                        height: 12,
                        borderRadius:
                            BorderRadius.all(Radius.circular(6))),
                  ],
                ),
              ),
              SizedBox(width: 8),
              SkeletonPulse(
                  width: 72,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(6))),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                SkeletonPulse(
                  width: 52,
                  height: 28,
                  borderRadius: BorderRadius.circular(20),
                ),
                SkeletonPulse(
                  width: 62,
                  height: 28,
                  borderRadius: BorderRadius.circular(20),
                ),
                SkeletonPulse(
                  width: 52,
                  height: 28,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portfolio total block while balances are loading.
class HomePortfolioHeaderSkeleton extends StatelessWidget {
  const HomePortfolioHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonPulse(width: 100, height: 13, borderRadius: BorderRadius.all(Radius.circular(6))),
          SizedBox(height: 12),
          SkeletonPulse(width: 200, height: 36, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(height: 8),
          SkeletonPulse(width: 140, height: 11, borderRadius: BorderRadius.all(Radius.circular(6))),
        ],
      ),
    );
  }
}

/// Generic list rows for address book / simple screens.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonPulse(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonPulse(width: 160, height: 14, borderRadius: BorderRadius.all(Radius.circular(6))),
                SizedBox(height: 8),
                SkeletonPulse(width: 220, height: 11, borderRadius: BorderRadius.all(Radius.circular(5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Swap screen placeholder while prices load.
class SwapScreenSkeleton extends StatelessWidget {
  const SwapScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonPulse(width: 56, height: 12, borderRadius: BorderRadius.all(Radius.circular(6))),
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              children: [
                SkeletonPulse(width: 30, height: 30, borderRadius: BorderRadius.all(Radius.circular(15))),
                SizedBox(width: 10),
                SkeletonPulse(width: 140, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: SkeletonPulse(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(22))),
          ),
          const SizedBox(height: 24),
          const SkeletonPulse(width: 40, height: 12, borderRadius: BorderRadius.all(Radius.circular(6))),
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3E),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonPulse(width: 80, height: 12, borderRadius: BorderRadius.all(Radius.circular(6))),
                SizedBox(height: 14),
                SkeletonPulse(width: 180, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
