import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'buat_pesanan_page.dart'; 
import 'detail_pesanan_page.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  List _pembelianList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRiwayatPembelian();
  }

  Future<void> _fetchRiwayatPembelian() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_riwayat_pembelian.php';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _pembelianList = jsonDecode(response.body);
        });
      } else {
        throw Exception('Gagal memuat data dari server (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToBuatPesanan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BuatPesananPage()),
    );
    // Jika halaman BuatPesananPage mengembalikan nilai true (artinya ada pesanan baru)
    if (result == true) {
      _fetchRiwayatPembelian(); // Muat ulang data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembelian', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToBuatPesanan,
        label: const Text('Pesanan Baru'),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: const Color(0xFF00A0E3),
        foregroundColor: Colors.white,
      ),
    );
  } 

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_pembelianList.isEmpty) {
      return const Center(child: Text("Belum ada riwayat pembelian."));
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayatPembelian,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _pembelianList.length,
        itemBuilder: (context, index) {
          final pembelian = _pembelianList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(pembelian['nama_supplier'] ?? 'Tanpa Supplier', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${pembelian['nomor_po'] ?? 'N/A'}\n${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(pembelian['tanggal_pesanan']))}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${NumberFormat('#,##0', 'id_ID').format(double.parse(pembelian['total_harga']))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(pembelian['status']),
                ],
              ),
              onTap: () async {
                 final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailPesananPage(idPembelian: pembelian['id'])),
                 );
                 if (result == true) {
                    _fetchRiwayatPembelian();
                 }
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatusChip(String? status) {
    Color chipColor = Colors.grey;
    String chipText = 'Unknown';
    IconData chipIcon = Icons.help_outline;

    switch (status) {
      case 'Dipesan':
        chipColor = Colors.orange;
        chipText = 'Dipesan';
        chipIcon = Icons.pending_actions;
        break;
      case 'Selesai':
        chipColor = Colors.green;
        chipText = 'Selesai';
        chipIcon = Icons.check_circle;
        break;
      case 'Dibatalkan':
        chipColor = Colors.red;
        chipText = 'Batal';
        chipIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: chipColor, size: 14),
          const SizedBox(width: 4),
          Text(chipText, style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}