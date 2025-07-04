import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'kasir_home_page.dart'; // Import halaman utama kasir

class StrukPage extends StatefulWidget {
  final int idTransaksi;
  final double uangDibayar;

  const StrukPage({
    super.key,
    required this.idTransaksi,
    required this.uangDibayar,
  });

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  Map<String, dynamic>? _strukData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStrukDetails();
  }

  Future<void> _fetchStrukDetails() async {
    // Ganti dengan IP Address Anda jika berbeda
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_struk_transaksi.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'id_transaksi': widget.idTransaksi}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _strukData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
         throw Exception('Gagal memuat data struk. Kode: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _buatPesananBaru() {
    // Kembali ke halaman home dan hapus semua halaman di atasnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const KasirHomePage()),
      (Route<dynamic> route) => false,
    );
  }

  void _cetakStruk() {
    // TODO: Tambahkan logika untuk mencetak struk ke printer thermal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur cetak struk belum tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Menghilangkan tombol kembali
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $_errorMessage', textAlign: TextAlign.center),
                ))
              : _buildStrukContent(),
      bottomNavigationBar: _strukData == null ? null : _buildBottomButtons(),
    );
  }

  Widget _buildStrukContent() {
    if (_strukData == null) {
      return const Center(child: Text('Data struk tidak ditemukan.'));
    }
    
    // Langsung gunakan nilai numerik dari API
    final totalBelanja = (_strukData!['total_transaksi_akhir'] as num).toDouble();
    final uangKembali = widget.uangDibayar - totalBelanja;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text('Transaksi Sukses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nota Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  Text('Waktu: ${DateFormat('d MMM y, HH:mm', 'id_ID').format(DateTime.parse(_strukData!['created_at']))}'),
                  Text('Kasir: ${_strukData!['nama_kasir'] ?? 'N/A'}'),
                  Text('Metode Bayar: ${_strukData!['metode_pembayaran'] ?? 'N/A'}'),
                  const Divider(height: 24),

                  // Daftar Item
                  ...(_strukData!['items'] as List).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['nama_barang'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Hapus double.parse(), langsung format angkanya
                              Text('  ${item['jumlah']} x ${NumberFormat('#,##0', 'id_ID').format(item['harga_satuan'])}'),
                              Text(NumberFormat('#,##0', 'id_ID').format(item['total'])),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 24),
                  
                  // Bagian Total
                  _buildTotalRow('Total Harga:', totalBelanja),
                  _buildTotalRow('Uang Dibayar:', widget.uangDibayar),
                  _buildTotalRow('Uang Kembali:', uangKembali, isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            'Rp ${NumberFormat('#,##0', 'id_ID').format(value)}',
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cetakStruk,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Cetak Struk'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor)
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _buatPesananBaru,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Pesanan Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A0E3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          ),
        ],
      ),
    );
  }
}