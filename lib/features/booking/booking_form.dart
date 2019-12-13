import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_thai_star_flutter/features/booking/blocs/booking_bloc.dart';
import 'package:my_thai_star_flutter/features/booking/blocs/booking_events.dart';
import 'package:my_thai_star_flutter/features/booking/blocs/booking_state.dart';
import 'package:my_thai_star_flutter/features/booking/models/booking.dart';
import 'package:form_validation_bloc/barrel.dart';

import 'package:my_thai_star_flutter/features/booking/bloc_date_picker.dart';
import 'package:my_thai_star_flutter/features/booking/bloc_form_field.dart';
import 'package:my_thai_star_flutter/ui_helper.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({Key key}) : super(key: key);

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  //Validation
  EmailValidationBloc _emailBloc = EmailValidationBloc();
  DateValidationBloc _dateBloc = DateValidationBloc();
  NameValidationBloc _nameBloc = NameValidationBloc();
  NumberValidationBloc _guestBloc = NumberValidationBloc();
  CheckboxValidationBloc _termsBloc = CheckboxValidationBloc();
  FormValidationBloc _formValidationBloc;

  //TextEditController
  TextEditingController _emailController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _guestController = TextEditingController();

  @override
  void initState() {
    _formValidationBloc = FormValidationBloc([
      _emailBloc,
      _dateBloc,
      _nameBloc,
      _guestBloc,
      _termsBloc,
    ]);

    BookingBloc bookingBloc = BlocProvider.of<BookingBloc>(context);

    _emailController.text =
        bookingBloc.currentState.booking?.organizerEmail ?? "";
    _nameController.text = bookingBloc.currentState.booking?.name ?? "";
    _guestController.text = bookingBloc.currentState.booking?.guests ?? "";

    if (bookingBloc.currentState.booking.date != null) {
      _dateController.text =
          Booking.dateFormat.format(bookingBloc.currentState.booking.date);
    }

    bookingBloc.state.listen(
      (BookingState state) {
        if (state is ConfirmedBookingState) {
          BlocProvider.of<BookingBloc>(context)
              .dispatch(ClearBookingContentsEvent());
          Scaffold.of(context).showSnackBar(SnackBar(
            duration: Duration(seconds: 3),
            content: Text("Booking Confirmed!\n" +
                "Booking Number: " +
                state.booking.bookingNumber),
          ));
        } else if (state is DeclinedBookingState) {
          Scaffold.of(context).showSnackBar(SnackBar(
            duration: Duration(seconds: 3),
            content: Text("Booking Declined\nReason: " + state.reason),
          ));
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          BlocDatePicker(
            validationBloc: _dateBloc,
            lable: 'Date and Time',
            errorHint: "Please select a Date",
            format: Booking.dateFormat,
            controller: _dateController,
            onChange: (DateTime date) => BlocProvider.of<BookingBloc>(context)
                .dispatch(SetDateEvent(date)),
          ),
          BlocFormField(
            validationBloc: _nameBloc,
            label: "Name",
            errorHint: 'Please enter your Name.',
            controller: _nameController,
            onChange: (String name) => BlocProvider.of<BookingBloc>(context)
                .dispatch(SetNameEvent(name)),
          ),
          BlocFormField(
            validationBloc: _emailBloc,
            label: "Email",
            errorHint: "Enter valid Email",
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            onChange: (String email) => BlocProvider.of<BookingBloc>(context)
                .dispatch(SetEmailEvent(email)),
          ),
          BlocFormField(
            validationBloc: _guestBloc,
            label: 'Table Guests',
            errorHint: 'Please enter the Number of Guests.',
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly
            ],
            keyboardType: TextInputType.number,
            controller: _guestController,
            onChange: (String guests) => BlocProvider.of<BookingBloc>(context)
                .dispatch(SetGuestsEvent(int.parse(guests))),
          ),
          BlocBuilder<CheckboxValidationBloc, ValidationState>(
            bloc: _termsBloc,
            builder: (context, ValidationState state) => _TermsCheckbox(
              state: state,
              termsBloc: _termsBloc,
            ),
          ),
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, BookingState state) {
              if (state is LoadingBookingState) {
                return _Loading();
              } else {
                return _Button(
                  formValidationBloc: _formValidationBloc,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailBloc.dispose();
    _nameBloc.dispose();
    _guestBloc.dispose();
    _dateBloc.dispose();
    _termsBloc.dispose();

    _formValidationBloc.dispose();

    _emailController.dispose();
    _dateController.dispose();
    _nameController.dispose();
    _guestController.dispose();

    super.dispose();
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    Key key,
    @required CheckboxValidationBloc termsBloc,
    @required ValidationState state,
  })  : _termsBloc = termsBloc,
        _state = state,
        super(key: key);

  final CheckboxValidationBloc _termsBloc;
  final ValidationState _state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        CheckboxListTile(
          title: Text("Accept terms"),
          onChanged: (bool value) {
            _termsBloc.dispatch(value);
            BlocProvider.of<BookingBloc>(context)
                .dispatch(SetTermsAcceptedEvent(value));
          },
          value: _state == ValidationState.valid,
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CircularProgressIndicator(),
      padding: EdgeInsets.only(
        right: UiHelper.card_margin,
        top: UiHelper.standart_padding,
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    Key key,
    @required FormValidationBloc formValidationBloc,
  })  : _formValidationBloc = formValidationBloc,
        super(key: key);

  final FormValidationBloc _formValidationBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormValidationBloc, ValidationState>(
      bloc: _formValidationBloc,
      builder: (context, ValidationState state) {
        return RaisedButton(
          child: Text(
            "Book Table",
          ),
          textColor: Colors.white,
          disabledTextColor: Colors.white,
          onPressed: state == ValidationState.valid
              ? () => BlocProvider.of<BookingBloc>(context)
                  .dispatch(RequestBookingEvent())
              : null,
        );
      },
    );
  }
}
