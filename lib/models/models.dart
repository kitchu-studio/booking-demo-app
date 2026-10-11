class AppUser {
  const AppUser({required this.id, required this.email, required this.name});

  final int id;
  final String email;
  final String name;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        name: (j['name'] as String?) ?? '',
      );
}

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.priceBaht,
  });

  final int id;
  final String name;
  final String description;
  final int durationMinutes;
  final int priceBaht;

  factory Service.fromJson(Map<String, dynamic> j) => Service(
        id: j['id'] as int,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        durationMinutes: j['duration_minutes'] as int,
        priceBaht: j['price_baht'] as int,
      );
}

class Slot {
  const Slot({
    required this.startsAt,
    required this.endsAt,
    required this.startLabel,
    required this.endLabel,
  });

  final DateTime startsAt;
  final DateTime endsAt;

  /// "HH:mm" exactly as the shop's clock shows it (taken from the API string,
  /// which already carries the shop's timezone), so it never shifts with the phone's timezone.
  final String startLabel;
  final String endLabel;

  factory Slot.fromJson(Map<String, dynamic> j) {
    final start = j['starts_at'] as String;
    final end = j['ends_at'] as String;
    return Slot(
      startsAt: DateTime.parse(start),
      endsAt: DateTime.parse(end),
      startLabel: _clock(start),
      endLabel: _clock(end),
    );
  }
}

String _clock(String iso) => iso.substring(11, 16);

/// One day's schedule for a service: opening hours plus the free start times.
class DaySlots {
  const DaySlots({
    required this.openHour,
    required this.closeHour,
    required this.slotMinutes,
    required this.durationMinutes,
    required this.slots,
  });

  final int openHour;
  final int closeHour;
  final int slotMinutes;
  final int durationMinutes;
  final List<Slot> slots;

  /// How many grid rows one appointment of this service covers.
  int get spanRows => (durationMinutes / slotMinutes).ceil();

  factory DaySlots.fromJson(Map<String, dynamic> j) => DaySlots(
        openHour: (j['open_hour'] as int?) ?? 9,
        closeHour: (j['close_hour'] as int?) ?? 18,
        slotMinutes: (j['slot_minutes'] as int?) ?? 30,
        durationMinutes: j['duration_minutes'] as int,
        slots: (j['slots'] as List<dynamic>)
            .map((e) => Slot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Booking {
  const Booking({
    required this.id,
    required this.serviceName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.note,
  });

  final int id;
  final String serviceName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String note;

  bool get isConfirmed => status == 'confirmed';

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        serviceName: j['service_name'] as String,
        startsAt: DateTime.parse(j['starts_at'] as String),
        endsAt: DateTime.parse(j['ends_at'] as String),
        status: j['status'] as String,
        note: (j['note'] as String?) ?? '',
      );
}
