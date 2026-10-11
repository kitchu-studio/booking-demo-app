import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../booking/booking_screen.dart';

final servicesProvider = FutureProvider.autoDispose<List<Service>>((ref) async {
  final res =
      await ref.watch(dioProvider).get<List<dynamic>>('/api/v1/services');
  return res.data!
      .map((e) => Service.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// The shop's price board: one line per service, name and price joined by a dotted leader.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key, required this.onBooked});

  /// Called after a booking is made, so the shell can show "my appointments".
  final VoidCallback onBooked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);

    return services.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(servicesProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('ร้านยังไม่เปิดรับจองบริการใด'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(servicesProvider.future),
          child: ListView(
            padding: const EdgeInsets.only(top: 20, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'เลือกบริการ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Palette.steel,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              for (final s in list) ...[
                _PriceRow(
                  service: s,
                  onTap: () async {
                    final booked = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(service: s),
                      ),
                    );
                    if (booked == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('จองแล้ว')),
                      );
                      onBooked();
                    }
                  },
                ),
                const Divider(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(service.name, style: text.titleMedium),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 14,
                      child: CustomPaint(
                        painter: _LeaderPainter(
                          Palette.steel.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  baht(service.priceBaht),
                  style: text.titleMedium?.copyWith(
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.description,
                    style: text.bodyMedium?.copyWith(color: Palette.steel),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${service.durationMinutes} นาที',
                  style: text.bodyMedium?.copyWith(color: Palette.steel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderPainter extends CustomPainter {
  const _LeaderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x + 1, size.height - 3), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}
