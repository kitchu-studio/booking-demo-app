import 'package:flutter_test/flutter_test.dart';

import 'package:booking_demo_app/models/models.dart';

void main() {
  test('Slot parses an RFC3339 time with offset', () {
    final slot = Slot.fromJson({
      'starts_at': '2026-10-12T10:00:00+07:00',
      'ends_at': '2026-10-12T11:00:00+07:00',
    });
    expect(slot.startLabel, '10:00');
    expect(slot.endLabel, '11:00');
    expect(slot.startsAt.toUtc().hour, 3);
    expect(slot.endsAt.difference(slot.startsAt), const Duration(hours: 1));
  });

  test('Booking parses API JSON and reports confirmed state', () {
    final b = Booking.fromJson({
      'id': 1,
      'service_id': 1,
      'service_name': 'ตัดผม',
      'starts_at': '2026-10-12T03:00:00Z',
      'ends_at': '2026-10-12T04:00:00Z',
      'status': 'confirmed',
      'note': '',
    });
    expect(b.isConfirmed, isTrue);
    expect(b.serviceName, 'ตัดผม');
  });

  test('Service parses price and duration', () {
    final s = Service.fromJson({
      'id': 2,
      'name': 'สระ-ไดร์',
      'description': '',
      'duration_minutes': 30,
      'price_baht': 150,
    });
    expect(s.durationMinutes, 30);
    expect(s.priceBaht, 150);
  });

  test('DaySlots falls back to default hours and computes row span', () {
    final d = DaySlots.fromJson({
      'duration_minutes': 120,
      'slots': <dynamic>[],
    });
    expect(d.openHour, 9);
    expect(d.closeHour, 18);
    expect(d.spanRows, 4);
  });
}
