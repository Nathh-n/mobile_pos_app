import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Impor SharedPreferences
import 'registration_page.dart';
import 'kasir/kasir_home_page.dart';
import 'gudang/gudang_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  // Fungsi untuk handle login
  Future<void> loginUser() async {
    // Validasi input tidak boleh kosong
    if (userIdController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // GANTI DENGAN IP ADDRESS ANDA
    const String apiUrl = 'http://192.168.89.181/api_flutter/login.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': userIdController.text,
          'password': passwordController.text,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userData = responseData['user'];
        final int userId = userData['id'];
        final String role = userData['role'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);

        if (role == 'Kasir') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KasirHomePage()));
        } else if (role == 'Gudang') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GudangHomePage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role tidak dikenal: $role')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } on TimeoutException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi timeout. Periksa kembali jaringan Anda.'))
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00B4FF),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text('Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: userIdController,
                  decoration: const InputDecoration(labelText: 'Username', hintText: 'Username', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A0E3),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Masuk'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum mempunyai akun? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationPage()));
                      },
                      child: const Text('Registrasi', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
