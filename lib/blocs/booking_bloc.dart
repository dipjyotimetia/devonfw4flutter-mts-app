import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:my_thai_star_flutter/blocs/booking_state.dart';
import 'package:my_thai_star_flutter/data/booking_service.dart';
import 'package:my_thai_star_flutter/models/booking.dart';
import 'package:my_thai_star_flutter/models/booking_response.dart';
import 'package:my_thai_star_flutter/repositories/api.dart';

class BookingBloc extends Bloc<Booking, BookingState> {
  final Api _api = BookingService();

  @override
  BookingState get initialState => DeclinedBookingState();

  @override
  Stream<BookingState> mapEventToState(Booking event) async* {
    BookingResponse response = await _api.post(event);
    if (response.accepted) {
      yield ConfirmedBookingState(
        bookingNumber: response.bookingNumber,
        currentBooking: event,
      );
    } else {
      yield DeclinedBookingState(
        currentBooking: event,
        error: response.statusCode,
      );
    }
  }
}
