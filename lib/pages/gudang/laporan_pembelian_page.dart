import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LaporanPembelianPage extends StatefulWidget {
  const LaporanPembelianPage({super.key});

  @override
  State<LaporanPembelianPage> createState() => _LaporanPembelianPageState();
}

class _LaporanPembelianPageState extends State<LaporanPembelianPage> {
  List _laporanList = [];
  double _totalPembelian = 0.0;
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

    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_laporan_pembelian.php';
    
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
        final data = jsonDecode(response.body);
        setState(() {
          _laporanList = data['pembelian'];
          _totalPembelian = data['total_pembelian_periode'].toDouble();
        });
      } else {
        throw Exception('Gagal memuat laporan pembelian');
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
        title: const Text('Laporan Pembelian'),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String displayTanggal = '${DateFormat('d MMM y', 'id_ID').format(_tanggalMulai)} - ${DateFormat('d MMM y', 'id_ID').format(_tanggalSelesai)}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pilihRentangTanggal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(displayTanggal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[600],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembelian (Selesai)', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    'Rp ${NumberFormat('#,##0', 'id_ID').format(_totalPembelian)}',
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    if (_laporanList.isEmpty) {
      return const Center(child: Text('Tidak ada pembelian pada periode ini.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchLaporan,
      child: ListView.builder(
        itemCount: _laporanList.length,
        itemBuilder: (context, index) {
          final trx = _laporanList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(trx['nomor_po'] ?? 'PO #${trx['id']}'),
              subtitle: Text('Supplier: ${trx['nama_supplier'] ?? 'N/A'}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${NumberFormat('#,##0', 'id_ID').format(double.parse(trx['total_pembelian']))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(DateFormat('d MMM y', 'id_ID').format(DateTime.parse(trx['tanggal_pesanan']))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
