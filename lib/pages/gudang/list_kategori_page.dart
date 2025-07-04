import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tes_capston/pages/kategori/kategori_page.dart';

class ListKategoriPage extends StatefulWidget {
  const ListKategoriPage({super.key});

  @override
  State<ListKategoriPage> createState() => _ListKategoriPageState();
}

class _ListKategoriPageState extends State<ListKategoriPage> {
  // Variabel untuk menampung daftar kategori dan status loading
  List _kategoriList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk mengambil data kategori saat halaman dimuat
    _fetchKategori();
  }

  /// Fungsi untuk mengambil data kategori dari API/database
  Future<void> _fetchKategori() async {
    // Setel ulang state sebelum mengambil data baru
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Ganti IP address ini sesuai dengan IP address lokal Anda
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_kategori.php';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Pastikan 'records' tidak null sebelum digunakan
          _kategoriList = data['records'] ?? [];
        });
      } else {
        // Tangani error dari server
        setState(() {
          _errorMessage = 'Gagal memuat data. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Tangani error jaringan atau timeout
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      // Hentikan loading setelah selesai
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke halaman tambah kategori
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KategoriPage()),
          );

          // Jika halaman KategoriPage kembali dengan hasil 'true' (sukses),
          // muat ulang daftar kategori
          if (result == true) {
            _fetchKategori();
          }
        },
        label: const Text('Kategori'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00A0E3),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Widget untuk membangun body utama berdasarkan state
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_kategoriList.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada kategori.\nSilakan tambahkan kategori baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Tampilkan daftar kategori jika data tersedia
    return RefreshIndicator(
      onRefresh: _fetchKategori, // Tarik untuk memuat ulang
      child: ListView.separated(
        itemCount: _kategoriList.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final kategori = _kategoriList[index];
          return ListTile(
            title: Text(kategori['nama_kategori']),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            // Anda bisa menambahkan fungsi edit/hapus di sini nanti
            // trailing: Icon(Icons.edit),
          );
        },
      ),
    );
  }
}
