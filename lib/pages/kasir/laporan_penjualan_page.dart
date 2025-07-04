import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage> {
  Map<String, dynamic>? _laporanData;
  bool _isLoading = true;
  String? _errorMessage;
  
  DateTime _tanggalMulai = DateTime.now().subtract(const Duration(days: 6));
  DateTime _tanggalSelesai = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_laporan_penjualan.php';
    
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
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _laporanData = jsonDecode(response.body);
        });
      } else {
        throw Exception('Gagal memuat laporan');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pilihRentangTanggal(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _tanggalMulai, end: _tanggalSelesai),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalSelesai = picked.end;
      });
      _fetchLaporan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : RefreshIndicator(
                  onRefresh: _fetchLaporan,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildRingkasanCard(),
                      const SizedBox(height: 16),
                      _buildMetodePembayaranCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final String displayTanggal = 
      '${DateFormat('d MMM y', 'id_ID').format(_tanggalMulai)} - ${DateFormat('d MMM y', 'id_ID').format(_tanggalSelesai)}';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pilihRentangTanggal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(displayTanggal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () { /* TODO: Download Logic */ },
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
    );
  }

  // --- REVISI: Widget _buildRingkasanCard disederhanakan ---
  Widget _buildRingkasanCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ringkasan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRingkasanItem("Penjualan Bersih", _laporanData?['penjualan_bersih'] ?? 0.0, isCurrency: true),
                _buildRingkasanItem("Penjualan Kotor", _laporanData?['penjualan_kotor'] ?? 0.0, isCurrency: true),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildRingkasanItem("Uang Diterima", _laporanData?['uang_diterima'] ?? 0.0, isCurrency: true),
                _buildRingkasanItem("Jumlah Transaksi", _laporanData?['jumlah_transaksi'] ?? 0, isCurrency: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanItem(String label, num value, {required bool isCurrency}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            isCurrency ? 'Rp ${NumberFormat('#,##0', 'id_ID').format(value)}' : value.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodePembayaranCard() {
    final paymentMethods = _laporanData?['metode_pembayaran'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Metode Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (paymentMethods.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Tidak ada data pembayaran."),
              )
            else
            ...paymentMethods.entries.map((entry) => _buildMetodeItem(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodeItem(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            'Rp ${NumberFormat('#,##0', 'id_ID').format(value)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
