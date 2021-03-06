import 'dart:async';

import 'package:form_bloc/form_bloc.dart';
import 'package:form_bloc/src/validation_state.dart';
import 'package:intl/intl.dart';

import 'field_bloc.dart';

///Responsible for checking if a given String matches the  
///defines [DateFormat]
class DateFieldBloc extends FieldBloc<String> {
  final DateFormat format;

  DateFieldBloc(this.format);

  @override
  ValidationState<String> get initialState => InitialState('');

  @override
  Stream<ValidationState<String>> mapEventToState(String event) async* {
    if (event.isEmpty) {
      yield InvalidState(event);
    } else {
      try {
        DateTime date = format.parse(event);
        if (date != null) {
          yield ValidState(event);
        } else {
          InvalidState(event);
        }
      } catch (e) {
        yield InvalidState(event);
      }
    }
  }
}
