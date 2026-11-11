import 'package:flutter/foundation.dart';

@immutable
class BookingsKeys {
  const BookingsKeys._();

  static const openBookings = ValueKey('open_bookings_screen');
  static const createBookingButton = ValueKey('create_booking_button');
  static const bookingList = ValueKey('booking_list_view');
  static const statusFilter = ValueKey('booking_status_filter');
  static const preferredDateInput = ValueKey('preferred_date_input');
  static const descriptionInput = ValueKey('booking_description_input');
  static const submitBooking = ValueKey('submit_booking_button');
  static const acceptButton = ValueKey('accept_booking_button');
  static const rejectButton = ValueKey('reject_booking_button');
  static const startProgressButton = ValueKey('start_progress_booking_button');
  static const completeButton = ValueKey('complete_booking_button');
  static const cancelButton = ValueKey('cancel_booking_button');
}
