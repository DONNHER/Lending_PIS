import 'package:flutter/material.dart';
import '../main.dart';

class SnackbarService {

  static void showSuccess(String message) {

    rootScaffoldMessengerKey.currentState
        ?.hideCurrentSnackBar();

    rootScaffoldMessengerKey.currentState
        ?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }


  static void showError(String message) {

    rootScaffoldMessengerKey.currentState
        ?.hideCurrentSnackBar();

    rootScaffoldMessengerKey.currentState
        ?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
  static void showLoading(String message) {

    rootScaffoldMessengerKey.currentState
        ?.hideCurrentSnackBar();

    rootScaffoldMessengerKey.currentState
        ?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(days: 1),
      ),
    );
  }
}