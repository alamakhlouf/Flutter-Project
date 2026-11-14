import 'booking_model.dart';

class ProviderAvailability {
  const ProviderAvailability({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.breakStart,
    this.breakEnd,
  });

  final String? id;
  final String dayOfWeek; // e.g., MONDAY, TUESDAY...
  final String startTime; // "09:00"
  final String endTime; // "17:00"
  final String? breakStart; // "13:00"
  final String? breakEnd; // "14:00"

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) {
    return ProviderAvailability(
      id: json['id']?.toString(),
      dayOfWeek: json['dayOfWeek']?.toString() ?? 'MONDAY',
      startTime: json['startTime']?.toString() ?? '09:00',
      endTime: json['endTime']?.toString() ?? '17:00',
      breakStart: json['breakStart']?.toString(),
      breakEnd: json['breakEnd']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      if (breakStart != null && breakStart!.isNotEmpty) 'breakStart': breakStart,
      if (breakEnd != null && breakEnd!.isNotEmpty) 'breakEnd': breakEnd,
    };
  }
}

class ProviderUnavailableDate {
  const ProviderUnavailableDate({
    required this.id,
    required this.date,
    this.reason,
    this.createdAt,
  });

  final String id;
  final DateTime date;
  final String? reason;
  final DateTime? createdAt;

  factory ProviderUnavailableDate.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'];
    DateTime parsedDate = DateTime.now();
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    }
    return ProviderUnavailableDate(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      reason: json['reason']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (reason != null) 'reason': reason,
    };
  }
}

class AvailableSlot {
  const AvailableSlot({
    required this.startDateTime,
    required this.endDateTime,
  });

  final DateTime startDateTime;
  final DateTime endDateTime;

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startDateTime: DateTime.tryParse(json['startDateTime']?.toString() ?? '') ?? DateTime.now(),
      endDateTime: DateTime.tryParse(json['endDateTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ProviderCalendarDay {
  const ProviderCalendarDay({
    required this.date,
    this.availability,
    this.unavailableDate,
    required this.bookings,
  });

  final DateTime date;
  final ProviderAvailability? availability;
  final ProviderUnavailableDate? unavailableDate;
  final List<BookingModel> bookings;

  factory ProviderCalendarDay.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'];
    DateTime parsedDate = DateTime.now();
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    }

    ProviderAvailability? av;
    if (json['availability'] is Map<String, dynamic>) {
      av = ProviderAvailability.fromJson(json['availability']);
    }

    ProviderUnavailableDate? un;
    if (json['unavailableDate'] is Map<String, dynamic>) {
      un = ProviderUnavailableDate.fromJson(json['unavailableDate']);
    }

    List<BookingModel> bookingsList = [];
    final bookingsRaw = json['bookings'];
    if (bookingsRaw is List) {
      bookingsList = bookingsRaw.map((b) => BookingModel.fromJson(b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b as Map))).toList();
    }

    return ProviderCalendarDay(
      date: parsedDate,
      availability: av,
      unavailableDate: un,
      bookings: bookingsList,
    );
  }
}
