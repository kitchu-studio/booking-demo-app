import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

final myBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final res =
      await ref.watch(dioProvider).get<List<dynamic>>('/api/v1/bookings');
  return res.data!
      .map((e) => Booking.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key, required this.onBookNow});

  final VoidCallback onBookNow;

  Future<void> _cancel(BuildContext context, WidgetRef ref, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิกนัดนี้?'),
        content: Text(
          '${b.serviceName}\n${thaiDateShort(b.startsAt)} ${timeHm(b.startsAt)} น.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('เก็บไว้'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยกเลิกนัด'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>('/api/v1/bookings/${b.id}/cancel');
      ref.invalidate(myBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ยกเลิกนัดแล้ว')));
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    final text = Theme.of(context).textTheme;

    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(myBookingsProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ยังไม่มีนัด', style: text.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: onBookNow,
                    child: const Text('จองคิว'),
                  ),
                ],
              ),
            ),
          );
        }

        final now = DateTime.now();
        final upcoming = list
            .where((b) => b.isConfirmed && b.endsAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final past = list
            .where((b) => !(b.isConfirmed && b.endsAt.isAfter(now)))
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

        Widget heading(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              child: Text(t, style: text.titleMedium),
            );

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myBookingsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (upcoming.isNotEmpty) heading('นัดที่กำลังมาถึง'),
              for (final b in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _Ticket(
                    booking: b,
                    onCancel: b.startsAt.isAfter(now)
                        ? () => _cancel(context, ref, b)
                        : null,
                  ),
                ),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                heading('ประวัติ'),
              ],
              for (final b in past)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _Ticket(booking: b),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.booking, this.onCancel});

  final Booking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final b = booking;
    final cancelled = !b.isConfirmed;
    final stubColor = cancelled ? Palette.steel : Palette.ink;
    final start = b.startsAt.toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: stubColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayShortLocal(start),
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  '${start.day}',
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontFeatures: tabularFigures,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  monthShortThai(start),
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 14,
            child: CustomPaint(painter: _PerforationPainter(stubColor)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 14, 14, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Palette.rule),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.serviceName,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cancelled ? Palette.steel : Palette.ink,
                      decoration:
                          cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timeHm(b.startsAt)} – ${timeHm(b.endsAt)} น.',
                    style: text.bodyLarge?.copyWith(
                      fontFeatures: tabularFigures,
                      color: cancelled ? Palette.steel : Palette.ink,
                    ),
                  ),
                  if (cancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'ยกเลิกแล้ว',
                        style: text.bodySmall?.copyWith(color: Palette.pole),
                      ),
                    ),
                  if (b.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        b.note,
                        style:
                            text.bodySmall?.copyWith(color: Palette.steel),
                      ),
                    ),
                  if (onCancel != null && !cancelled)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onCancel,
                        child: const Text('ยกเลิกนัด'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed tear line between stub and body, with paper-coloured notches top and bottom.
class _PerforationPainter extends CustomPainter {
  _PerforationPainter(this.stub);

  final Color stub;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 0.5, size.height),
      Paint()..color = stub,
    );
    final dash = Paint()
      ..color = Palette.rule
      ..strokeWidth = 1.5;
    for (double y = 12; y < size.height - 12; y += 8) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 4), dash);
    }
    final hole = Paint()..color = Palette.paper;
    canvas.drawCircle(Offset(cx, 0), 7, hole);
    canvas.drawCircle(Offset(cx, size.height), 7, hole);
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.stub != stub;
}
