import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _service = AuthService();

  var isLoading = false.obs;

  Future<bool> checkUserExists() async {
    return await _service.hasPassword();
  }

  Future<bool> login(String password) async {
    isLoading.value = true;
    bool result = await _service.verifyPassword(password);
    isLoading.value = false;
    return result;
  }

  Future<void> setPassword(String password) async {
    await _service.savePassword(password);
  }
}
