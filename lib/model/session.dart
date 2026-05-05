// filepath: lib\model\session.dart
import 'user.dart';

class Session {
  final User user;
  final String token; // Token de sesión (para futuro)
  final DateTime loginTime;

  Session({
    required this.user,
    required this.token,
    required this.loginTime,
  });

  bool get isValid => DateTime.now().difference(loginTime).inHours < 24;
}