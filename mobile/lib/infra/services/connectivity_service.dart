import 'dart:io';
// ignore: unused_import
import 'package:flutter/foundation.dart';

class ConnectivityService {
  Future<bool> hasStableInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> triplePingCheck() async {
    int sucessos = 0;
    for (int i = 0; i < 3; i++) {
      if (await hasStableInternet()) sucessos++;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return sucessos == 3;
  }
}