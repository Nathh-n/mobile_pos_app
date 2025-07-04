import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final double amount;
  final String time;
  final String date;
  final String status;

  Transaction({
    required this.id,
    required this.amount,
    required this.time,
    required this.date,
    required this.status,
  });

  // --- FUNGSI INI TELAH DIPERBARUI UNTUK MENANGANI NULL ---
  factory Transaction.fromJson(Map<String, dynamic> json) {
    final idValue = json['id_transaksi'] != null ? json['id_transaksi'].toString() : 'N/A';
    
    // Cek jika 'total_belanja' null, jika ya, gunakan 0.0
    final amountValue = json['total_belanja'] != null 
        ? double.tryParse(json['total_belanja'].toString()) ?? 0.0 
        : 0.0;

    return Transaction(
      id: "TRX-${idValue}",
      amount: amountValue, // Gunakan nilai yang sudah aman
      time: json['waktu'] ?? 'N/A',
      date: json['tanggal'] ?? 'Tanggal tidak diketahui',
      status: json['status_pembayaran'] ?? 'N/A',
    );
  }
}

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  Map<String, double> _dailyTotals = {};
  String _errorMessage = '';

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Ganti dengan IP Address Anda jika berbeda
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_transaksi.php';
    
    final Map<String, String?> body = {};
    if (_selectedDateRange != null) {
      body['tanggal_mulai'] = DateFormat('y-MM-dd').format(_selectedDateRange!.start);
      body['tanggal_selesai'] = DateFormat('y-MM-dd').format(_selectedDateRange!.end);
    }
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _processData(data);
      } else {
        throw Exception('Gagal memuat data (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil data riwayat: $e';
        _transactions = [];
        _groupedTransactions = {};
        _dailyTotals = {};
      });
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processData(List<dynamic> data) {
      final transactions = data.map((item) => Transaction.fromJson(item)).toList();
      final grouped = <String, List<Transaction>>{};
      final totals = <String, double>{};

      for (var tx in transactions) {
        if (!grouped.containsKey(tx.date)) {
          grouped[tx.date] = [];
          totals[tx.date] = 0.0;
        }
        grouped[tx.date]!.add(tx);
        totals[tx.date] = totals[tx.date]! + tx.amount;
      }

      setState(() {
        _transactions = transactions;
        _groupedTransactions = grouped;
        _dailyTotals = totals;
      });
  }

  Future<void> _pilihRentangTanggal() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchTransactionHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              const Text('Gagal Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchTransactionHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }

    String dateFilterText = 'Semua Waktu';
    if (_selectedDateRange != null) {
      dateFilterText = '${DateFormat('d MMM y', 'id_ID').format(_selectedDateRange!.start)} - ${DateFormat('d MMM y', 'id_ID').format(_selectedDateRange!.end)}';
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactionHistory,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: TextEditingController(text: dateFilterText),
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _selectedDateRange != null ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                    _fetchTransactionHistory();
                  },
                ) : null,
              ),
              onTap: _pilihRentangTanggal,
            ),
          ),
          if (_transactions.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Tidak ada riwayat pada periode yang dipilih.', textAlign: TextAlign.center),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _groupedTransactions.keys.map((date) {
                  final transactionsOnDate = _groupedTransactions[date]!;
                  final dailyTotal = _dailyTotals[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(date, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Rp ${NumberFormat('#,##0', 'id_ID').format(dailyTotal)}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      ...transactionsOnDate.map((tx) => _buildTransactionCard(tx)).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rp ${NumberFormat('#,##0', 'id_ID').format(tx.amount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Pukul ${tx.time}', style: TextStyle(color: Colors.grey[600])),
                  Text(tx.id, style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 59, 182, 63),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tx.status,
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}