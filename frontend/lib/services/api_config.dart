import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api'; // Emulador Android
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }
    return 'http://localhost:3000/api';
  }
}