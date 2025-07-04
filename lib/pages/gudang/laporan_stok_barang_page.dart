import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Untuk format tanggal

class LaporanStokBarangPage extends StatefulWidget {
  const LaporanStokBarangPage({super.key});

  @override
  State<LaporanStokBarangPage> createState() => _LaporanStokBarangPageState();
}

class _LaporanStokBarangPageState extends State<LaporanStokBarangPage> {
  // --- State untuk menampung data dan mengontrol UI ---
  List _laporanStok = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // State untuk rentang tanggal, default 7 hari terakhir
  DateTime _tanggalMulai = DateTime.now().subtract(const Duration(days: 6));
  DateTime _tanggalSelesai = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Panggil API saat halaman pertama kali dimuat
    _fetchLaporanStok();
  }

  /// Fungsi untuk memanggil API laporan_stok.php
  Future<void> _fetchLaporanStok() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Ganti dengan IP Address Anda
    const String apiUrl = 'http://192.168.89.181/api_flutter/laporan_stok.php';
    
    // Format tanggal ke YYYY-MM-DD untuk dikirim ke API
    final String formattedTglMulai = DateFormat('y-MM-dd').format(_tanggalMulai);
    final String formattedTglSelesai = DateFormat('y-MM-dd').format(_tanggalSelesai);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'tanggal_mulai': formattedTglMulai,
          'tanggal_selesai': formattedTglSelesai,
        }),
      ).timeout(const Duration(seconds: 20)); // Tambah timeout untuk query kompleks

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _laporanStok = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat laporan. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fungsi untuk menampilkan dialog pemilih rentang tanggal
  Future<void> _pilihRentangTanggal(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _tanggalMulai, end: _tanggalSelesai),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && (picked.start != _tanggalMulai || picked.end != _tanggalSelesai)) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
      // Ambil data baru setelah tanggal diubah
      _fetchLaporanStok();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok Barang'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Widget untuk header yang berisi filter dan tombol download
  Widget _buildHeader() {
    // Format tanggal untuk ditampilkan di tombol
    final String displayTanggal = 
      '${DateFormat('d MMM y', 'id_ID').format(_tanggalMulai)} - ${DateFormat('d MMM y', 'id_ID').format(_tanggalSelesai)}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pilihRentangTanggal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayTanggal, style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Logika untuk download laporan
            },
            icon: const Icon(Icons.download, size: 20),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
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
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_laporanStok.isEmpty) {
      return const Center(
        child: Text('Tidak ada data laporan untuk periode ini.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLaporanStok,
      child: ListView.builder(
        itemCount: _laporanStok.length,
        itemBuilder: (context, index) {
          final item = _laporanStok[index];
          return _buildReportItem(item);
        },
      ),
    );
  }

  /// Widget untuk menampilkan satu item dalam daftar laporan
  Widget _buildReportItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama_barang'] ?? 'Nama Tidak Ditemukan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Stok Awal : ${item['stok_awal']}'),
                Text('Stok Masuk : ${item['stok_masuk']}', style: const TextStyle(color: Colors.green)),
                Text('Stok Keluar : ${item['stok_keluar']}', style: const TextStyle(color: Colors.red)),
                Text('Stok Akhir : ${item['stok_akhir']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
