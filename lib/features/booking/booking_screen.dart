import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../bookings/my_bookings_screen.dart';

/// One day's schedule for a service. Family key: (serviceId, 'yyyy-MM-dd').
final slotsProvider =
    FutureProvider.autoDispose.family<DaySlots, (int, String)>((ref, q) async {
  final res = await ref.watch(dioProvider).get<Map<String, dynamic>>(
    '/api/v1/services/${q.$1}/slots',
    queryParameters: {'date': q.$2},
  );
  return DaySlots.fromJson(res.data!);
});

/// The appointment book: every half hour of the day is a line; free lines can be taken.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.service});

  final Service service;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const _daysAhead = 14;
  static const _rowHeight = 52.0;

  late final List<DateTime> _days;
  late DateTime _date;
  Slot? _slot;
  bool _saving = false;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(
      _daysAhead,
      (i) => DateTime(now.year, now.month, now.day + i),
    );
    _date = _days.first;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final slot = _slot;
    if (slot == null) return;
    setState(() => _saving = true);

    final note = _note.text.trim();
    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/api/v1/bookings',
        data: {
          'service_id': widget.service.id,
          'starts_at': slot.startsAt.toUtc().toIso8601String(),
          if (note.isNotEmpty) 'note': note,
        },
      );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ref.invalidate(slotsProvider);
      setState(() {
        _saving = false;
        _slot = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final text = Theme.of(context).textTheme;
    final day = ref.watch(slotsProvider((service.id, apiDate(_date))));

    return Scaffold(
      appBar: AppBar(title: Text(service.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Text(
                  '${service.durationMinutes} นาที',
                  style: text.bodyMedium?.copyWith(color: Palette.steel),
                ),
                const Spacer(),
                Text(
                  baht(service.priceBaht),
                  style: text.titleMedium?.copyWith(
                    fontFeatures: tabularFigures,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _DayStrip(
            days: _days,
            selected: _date,
            onSelect: (d) => setState(() {
              _date = d;
              _slot = null;
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(thaiDateLong(_date), style: text.titleSmall),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: day.when(
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
                        onPressed: () => ref.invalidate(slotsProvider),
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (d) => _Ledger(
                day: d,
                rowHeight: _rowHeight,
                selected: _slot,
                onSelect: (s) => setState(() => _slot = s),
              ),
            ),
          ),
          _BottomBar(
            slot: _slot,
            saving: _saving,
            note: _note,
            onConfirm: _confirm,
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final d = days[i];
          final isSel = d == selected;
          return InkWell(
            onTap: () => onSelect(d),
            child: Container(
              width: 52,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSel ? Palette.pole : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    weekdayShortLocal(d),
                    style: text.bodySmall?.copyWith(
                      color: isSel ? Palette.ink : Palette.steel,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.day}',
                    style: text.titleLarge?.copyWith(
                      fontFeatures: tabularFigures,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                      color: isSel ? Palette.ink : Palette.steel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.day,
    required this.rowHeight,
    required this.selected,
    required this.onSelect,
  });

  final DaySlots day;
  final double rowHeight;
  final Slot? selected;
  final ValueChanged<Slot> onSelect;

  static String _hm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = ((day.closeHour - day.openHour) * 60 / day.slotMinutes).ceil();
    final free = {for (final s in day.slots) s.startLabel: s};

    int? selStart;
    if (selected != null) {
      final i = List.generate(
        count,
        (i) => _hm(day.openHour * 60 + i * day.slotMinutes),
      ).indexOf(selected!.startLabel);
      if (i >= 0) selStart = i;
    }

    if (day.slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'วันนี้คิวเต็มแล้ว ลองเลือกวันอื่น',
            style: text.bodyLarge?.copyWith(color: Palette.steel),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: count,
      itemExtent: rowHeight,
      itemBuilder: (context, i) {
        final label = _hm(day.openHour * 60 + i * day.slotMinutes);
        final slot = free[label];
        final inSel =
            selStart != null && i >= selStart && i < selStart + day.spanRows;
        final isFirst = inSel && i == selStart;

        final Color bg = inSel ? Palette.ink : Colors.transparent;
        final Color fg = inSel
            ? Colors.white
            : (slot != null ? Palette.ink : Palette.steel);

        return InkWell(
          onTap: slot == null ? null : () => onSelect(slot),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                bottom: BorderSide(
                  color: inSel ? Palette.ink : Palette.rule,
                  width: 1,
                ),
                left: BorderSide(
                  color: inSel ? Palette.pole : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    label,
                    style: text.titleMedium?.copyWith(
                      color: fg,
                      fontFeatures: tabularFigures,
                      fontWeight: slot != null || inSel
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const Spacer(),
                if (isFirst)
                  Text(
                    '${selected!.startLabel} – ${selected!.endLabel} น.',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontFeatures: tabularFigures,
                    ),
                  )
                else if (!inSel && slot == null)
                  Text(
                    'ไม่ว่าง',
                    style: text.bodySmall?.copyWith(color: Palette.steel),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.slot,
    required this.saving,
    required this.note,
    required this.onConfirm,
  });

  final Slot? slot;
  final bool saving;
  final TextEditingController note;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final s = slot;
    return Container(
      decoration: const BoxDecoration(
        color: Palette.paper,
        border: Border(top: BorderSide(color: Palette.rule)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s != null) ...[
              TextField(
                controller: note,
                maxLength: 300,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'หมายเหตุถึงร้าน (ไม่บังคับ)',
                  counterText: '',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (s == null || saving) ? null : onConfirm,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        s == null
                            ? 'เลือกเวลาที่ว่าง'
                            : 'จอง ${s.startLabel} – ${s.endLabel} น.',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
