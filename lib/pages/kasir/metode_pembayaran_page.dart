import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'struk_page.dart';

class MetodePembayaranPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double transactionTotal;

  const MetodePembayaranPage({
    super.key,
    required this.cartItems,
    required this.transactionTotal,
  });

  @override
  State<MetodePembayaranPage> createState() => _MetodePembayaranPageState();
}

class _MetodePembayaranPageState extends State<MetodePembayaranPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _uangDiterimaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uangDiterimaController.dispose();
    super.dispose();
  }

  // --- FUNGSI INI TELAH DIPERBARUI DENGAN VALIDASI ---
  Future<void> _saveTransaction(BuildContext context) async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // --- PERUBAHAN 1: Tentukan Metode Pembayaran ---
    final String metodePembayaran = _tabController.index == 0 ? 'Tunai' : 'QRIS';

    // --- PERUBAHAN 2: Validasi Input untuk Pembayaran Tunai ---
    if (metodePembayaran == 'Tunai') {
      if (_uangDiterimaController.text.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Harap masukkan jumlah uang yang diterima.')),
        );
        return; // Hentikan proses jika input kosong
      }
      final double uangDiterima = double.tryParse(_uangDiterimaController.text.replaceAll('.', '')) ?? 0;
      if (uangDiterima < widget.transactionTotal) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Jumlah uang yang dibayar kurang dari total tagihan.')),
        );
        return; // Hentikan proses jika uang kurang
      }
    }

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? idKasir = prefs.getInt('user_id');

      if (idKasir == null) {
        if (mounted) navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Error: Sesi kasir tidak ditemukan. Silakan login ulang.')),
        );
        return;
      }

      const String apiUrl = 'http://192.168.89.181/api_flutter/simpan_transaksi.php';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'id_kasir': idKasir,
          'total_kuantitas_barang': widget.cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int)),
          'subtotal_transaksi': widget.transactionTotal,
          'total_transaksi_akhir': widget.transactionTotal,
          'metode_pembayaran': metodePembayaran, // Kirim metode pembayaran yang benar
          'status_transaksi': 'Selesai',
          'cart_items': widget.cartItems,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      await navigator.maybePop(); // Tutup dialog loading

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final int idTransaksiBaru = responseData['transaksi_id'];
        
        double uangDibayar = 0;
        if (metodePembayaran == 'Tunai') {
          uangDibayar = double.tryParse(_uangDiterimaController.text.replaceAll('.', '')) ?? 0;
        } else {
          // Untuk QRIS, uang dibayar sama dengan total
          uangDibayar = widget.transactionTotal;
        }

        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => StrukPage(
              idTransaksi: idTransaksiBaru,
              uangDibayar: uangDibayar,
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal menyimpan. Error: ${responseData['message'] ?? 'Unknown Error'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (navigator.canPop()) await navigator.maybePop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Terjadi error saat menyimpan: $e')),
      );
    }
  }

  // --- Sisa kode build method tidak ada perubahan signifikan ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Pembayaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Tagihan', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(widget.transactionTotal)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00A0E3)),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF00A0E3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00A0E3),
            tabs: const [Tab(text: 'Tunai'), Tab(text: 'Non Tunai')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTunaiView(), _buildNonTunaiView()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Panggil fungsi tanpa argumen, karena metode pembayaran diambil dari TabController
            _saveTransaction(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A0E3),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: const Text('Simpan Transaksi', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildTunaiView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uang Diterima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _uangDiterimaController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _uangDiterimaController.text = widget.transactionTotal.toStringAsFixed(0).replaceAll('.', '');
                });
              },
              child: const Text('Uang Pas'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00A0E3)),
                foregroundColor: const Color(0xFF00A0E3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonTunaiView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('QRIS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Icon(Icons.qr_code_2, size: 150, color: Colors.grey[800]),
            const SizedBox(height: 16),
            const Text('Pindai kode QR untuk melakukan pembayaran.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}