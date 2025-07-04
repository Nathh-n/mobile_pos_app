import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'list_kategori_page.dart';
import 'manajemen_supplier_page.dart';
import '../login_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _namaLengkap;
  String? _username;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        _errorMessage = 'Sesi tidak ditemukan. Silakan login kembali.';
        _isLoading = false;
      });
      return;
    }

    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_user_profil.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _namaLengkap = data['nama_lengkap'];
          _username = data['username'];
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Gagal memuat data profil.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan. Periksa koneksi Anda.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logoutUser();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 1 ? 2 : 1;
    for (var i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0];
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildMenuView(),
      ),
    );
  }

  ListView _buildMenuView() {
    return ListView(
      children: [
        _buildProfileSection(
          context,
          namaLengkap: _namaLengkap,
          username: _username,
        ),
        _buildSectionHeader('Pengaturan'),
        _buildMenuItem(
          icon: Icons.category_outlined,
          iconBackgroundColor: Colors.blue.shade100,
          iconColor: Colors.blue.shade800,
          title: 'Kategori',
          subtitle: 'Kelola kategori stok Anda',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ListKategoriPage()),
            );
          },
        ),
        // --- PERUBAHAN DI SINI ---
        _buildMenuItem(
          icon: Icons.people_alt_outlined,
          iconBackgroundColor: Colors.teal.shade100,
          iconColor: Colors.teal.shade800,
          title: 'Supplier',
          subtitle: 'Kelola data supplier',
          onTap: () {
            // 2. Navigasi ke halaman Manajemen Supplier
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManajemenSupplierPage()),
            );
          },
        ),
        // --- AKHIR PERUBAHAN ---
        _buildMenuItem(
            icon: Icons.translate_outlined,
            iconBackgroundColor: Colors.orange.shade100,
            iconColor: Colors.orange.shade800,
            title: 'Bahasa',
            subtitle: 'Ganti bahasa yang akan digunakan',
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.support_agent_outlined,
            iconBackgroundColor: Colors.green.shade100,
            iconColor: Colors.green.shade800,
            title: 'Hubungi Kami',
            subtitle: 'Tutorial, Hubungi Kami',
            onTap: () {}),
        _buildMenuItem(
            icon: Icons.info_outline,
            iconBackgroundColor: Colors.purple.shade100,
            iconColor: Colors.purple.shade800,
            title: 'Tentang',
            subtitle: 'Saran, Kebijakan Privasi',
            onTap: () {}),
        const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
        _buildLogoutButton(onTap: _showLogoutDialog),
      ],
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Coba Lagi'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, {String? namaLengkap, String? username}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF00A0E3),
            child: Text(
              _getInitials(namaLengkap),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color.fromARGB(255, 246, 252, 255),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaLengkap ?? 'Nama Pengguna',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  username ?? 'username',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required Color iconBackgroundColor,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBackgroundColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
      ),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.exit_to_app, color: Colors.red),
        title: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
      ),
    );
  }
}
