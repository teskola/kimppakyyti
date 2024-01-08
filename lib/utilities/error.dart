import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum RouteError { unknownError, notFound, quoataExceeded }

enum Errors { networkError }

class Error implements Exception {
  String? message;
  Errors? error;
  Error({this.message, this.error});
}

class SignInException extends Error {
  SignInException({super.message, super.error});
}

class RouteException extends Error {
  final RouteError? type;
  RouteException({this.type, super.message, super.error});
}

class ErrorSnackbar {
  static String _snackBarMessage(BuildContext context, Error ex) {
    if (ex.error != null && ex.error == Errors.networkError) {
      return AppLocalizations.of(context).network_error;
    }
    switch (ex.runtimeType) {
      case const (SignInException):
        return AppLocalizations.of(context).sign_in_error;
      case const (RouteException):
        switch ((ex as RouteException).type) {
          case RouteError.notFound:
            return AppLocalizations.of(context).route_not_found;
          case RouteError.quoataExceeded:
            return AppLocalizations.of(context).quoata_exceeded;
          case RouteError.unknownError:
            return AppLocalizations.of(context).error;
          default:
            throw UnimplementedError();
        }
      default:
        return ex.message ?? AppLocalizations.of(context).error;
    }
  }

  static void show(BuildContext context, Error error) {
    final snackBar = SnackBar(content: Text(_snackBarMessage(context, error)));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    debugPrint(error.message);
  }
}
