import 'package:flutter/material.dart';
import 'metode_pembayaran_page.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double transactionTotal;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.transactionTotal,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late List<Map<String, dynamic>> _currentCartItems;
  late double _currentTransactionTotal;

  @override
  void initState() {
    super.initState();
    _currentCartItems = widget.cartItems.map((item) => Map<String, dynamic>.from(item)).toList();
    _currentTransactionTotal = widget.transactionTotal;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      Map<String, dynamic> item = _currentCartItems[index];
      int currentQuantity = item['quantity'] as int;
      double itemPrice = item['price'] as double;
      int newQuantity = currentQuantity + delta;

      if (newQuantity <= 0) {
        _currentTransactionTotal -= (itemPrice * currentQuantity);
        _currentCartItems.removeAt(index);
      } else {
        double oldTotalPrice = item['total_price'] as double;
        double newTotalPrice = itemPrice * newQuantity;
        item['quantity'] = newQuantity;
        item['total_price'] = newTotalPrice;
        _currentTransactionTotal += (newTotalPrice - oldTotalPrice);
      }

      if (_currentCartItems.isEmpty) {
        Navigator.pop(context, _currentCartItems);
      }
    });
  }

  // --- FUNGSI _saveTransaction SEKARANG AKAN DIPINDAHKAN KE METODE_PEMBAYARAN_PAGE ---
  // --- KITA HAPUS DARI SINI UNTUK MENGHINDARI DUPLIKASI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _currentCartItems);
          },
        ),
        title: const Text('Rincian Belanja'), // Judul diubah agar lebih sesuai
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentCartItems.isEmpty
                ? const Center(child: Text('Tidak ada barang di keranjang.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _currentCartItems.length,
                    itemBuilder: (context, index) {
                      final item = _currentCartItems[index];
                      final String? itemName = item['name'];
                      final String initial = itemName != null && itemName.isNotEmpty
                          ? itemName[0].toUpperCase()
                          : '?';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Nama tidak tersedia',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Rp ${item['price'].toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 105, 105, 105)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () => _updateQuantity(index, -1),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      item['quantity'].toString(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () => _updateQuantity(index, 1),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${_currentTransactionTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF00A0E3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _currentCartItems.isEmpty ? null : () async {
                      // **MODIFIKASI UTAMA**
                      // Navigasi ke halaman metode pembayaran
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MetodePembayaranPage(
                            cartItems: _currentCartItems,
                            transactionTotal: _currentTransactionTotal,
                          ),
                        ),
                      );

                      // Jika transaksi berhasil disimpan di halaman berikutnya
                      // dan halaman tersebut mengembalikan nilai (misal: true),
                      // maka kita kembali ke halaman sebelumnya (KasirHomePage)
                      // dengan keranjang yang sudah dikosongkan.
                      if (result == true) {
                        Navigator.pop(context, []); // Kirim keranjang kosong kembali
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A0E3),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Pilih Pembayaran', style: TextStyle(fontSize: 18)), // Teks tombol diubah
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}