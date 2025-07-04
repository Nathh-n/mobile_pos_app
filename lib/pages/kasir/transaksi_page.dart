// Salin semua isi dari kasir_home_page.dart yang Anda berikan
// Kemudian, ubah seperti di bawah ini:

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'payment_page.dart';

// Ganti nama class dari KasirHomePage menjadi TransaksiPage
class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  // Ganti nama State class
  State<TransaksiPage> createState() => _TransaksiPageState();
}

// Ganti nama State class
class _TransaksiPageState extends State<TransaksiPage> {
  // --- SEMUA KODE STATE DARI _KasirHomePageState ANDA TETAP DI SINI ---
  // (State untuk UI, Data Barang, Input Manual, Transaksi, dll)
  
  // State untuk UI dan Navigasi
  final List<bool> _toggleSelections = [false, true]; // [Manual, Katalog]
  bool _isLoading = true;
  
  // State untuk Data Barang dan Filtering
  List _barangList = [];
  List _filteredBarangList = [];
  final TextEditingController _searchController = TextEditingController();

  // State untuk Input Manual
  final TextEditingController _manualInputController = TextEditingController();
  String _currentManualAmount = "0";

  // State untuk Transaksi
  List<Map<String, dynamic>> _cartItems = [];
  double _transactionTotal = 0.0;
  bool _showPayBar = false;

  // State untuk Sorting dan Filter Kategori
  bool _isSortedAscending = true;
  List<String> _kategoriList = [];
  String? _selectedKategori;

  @override
  void initState() {
    super.initState();
    if (_toggleSelections[1]) {
      _fetchInitialData();
    }
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchBarangForKasir(),
      _fetchKategori(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchBarangForKasir() async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_barang_kasir.php';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _barangList = data['records'] ?? [];
          _applyFilters();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data barang: $e')));
    }
  }

  Future<void> _fetchKategori() async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/sortir_kategori.php';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _kategoriList = data.map((item) => item.toString()).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data kategori: $e')));
    }
  }

  void _applyFilters() {
    List filteredList = List.from(_barangList);
    String query = _searchController.text.toLowerCase();

    if (_selectedKategori != null) {
      filteredList = filteredList.where((barang) {
        return barang['nama_kategori'] == _selectedKategori;
      }).toList();
    }

    if (query.isNotEmpty) {
      filteredList = filteredList.where((barang) {
        final String namaBarang = barang['nama_barang']?.toString().toLowerCase() ?? '';
        return namaBarang.contains(query);
      }).toList();
    }

    setState(() {
      _filteredBarangList = filteredList;
    });
  }

  void _sortBarangList() {
    setState(() {
      if (_isSortedAscending) {
        _filteredBarangList.sort((a, b) => (b['nama_barang'] ?? '').compareTo(a['nama_barang'] ?? ''));
      } else {
        _filteredBarangList.sort((a, b) => (a['nama_barang'] ?? '').compareTo(b['nama_barang'] ?? ''));
      }
      _isSortedAscending = !_isSortedAscending;
    });
  }

  void _updateManualInput(String value) {
    setState(() {
      if (value == 'C') {
        _manualInputController.clear();
        _currentManualAmount = "0";
      } else if (value == 'DEL') {
        if (_manualInputController.text.isNotEmpty) {
          _manualInputController.text = _manualInputController.text.substring(0, _manualInputController.text.length - 1);
        }
        _currentManualAmount = _manualInputController.text.isEmpty ? "0" : _manualInputController.text;
      } else {
        if (_currentManualAmount == "0" && value != "000") {
          _manualInputController.text = value;
        } else if (value == "000" && _currentManualAmount == "0") {
          // do nothing
        } else {
          _manualInputController.text += value;
        }
        _currentManualAmount = _manualInputController.text;
      }
    });
  }

  void _addItemToTransaction({
    required String name,
    required double price,
    int quantity = 1,
    String? itemId,
  }) {
    setState(() {
      int existingIndex = -1;
      if (itemId != null) {
        existingIndex = _cartItems.indexWhere((item) => item['id'] == itemId);
      }
      
      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity'] += quantity;
        _cartItems[existingIndex]['total_price'] += (price * quantity);
      } else {
        _cartItems.add({
          'id': itemId,
          'name': name,
          'price': price,
          'quantity': quantity,
          'total_price': price * quantity,
        });
      }
      _transactionTotal += (price * quantity);
      _showPayBar = true;
    });
  }

  void _handlePay() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja kosong.')),
      );
      return;
    }

    final List<Map<String, dynamic>>? returnedCartItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cartItems: List.from(_cartItems),
          transactionTotal: _transactionTotal,
        ),
      ),
    );

    if (returnedCartItems != null) {
      setState(() {
        _cartItems = returnedCartItems;
        _transactionTotal = _cartItems.fold(0.0, (sum, item) => sum + (item['total_price'] as double));
        _showPayBar = _cartItems.isNotEmpty;
        _manualInputController.clear();
        _currentManualAmount = "0";
      });
    }
  }

  // --- MODIFIKASI build METHOD ---
  // Hapus Scaffold dan BottomNavigationBar, kembalikan langsung body-nya
  @override
  Widget build(BuildContext context) {
    // Scaffold dan BottomNavigationBar akan ada di 'kasir_home_page.dart'
    // Widget ini hanya mengembalikan bagian body dan app bar spesifik untuknya.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: ToggleButtons(
          isSelected: _toggleSelections,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _toggleSelections.length; i++) {
                _toggleSelections[i] = i == index;
              }
              if (_toggleSelections[1] && _barangList.isEmpty) {
                _fetchInitialData();
              }
            });
          },
          borderRadius: BorderRadius.circular(8.0),
          selectedColor: Colors.white,
          fillColor: const Color(0xFF00A0E3),
          color: const Color(0xFF00A0E3),
          constraints: const BoxConstraints(minHeight: 35.0, minWidth: 100.0),
          children: const <Widget>[Text('Manual'), Text('Katalog')],
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_toggleSelections[1])
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Barang',
                        prefixIcon: const Icon(Icons.search, size: 24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: const Color(0xFF00A0E3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _sortBarangList,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.sort_by_alpha, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (String result) {
                      setState(() {
                        _selectedKategori = (result == "semua") ? null : result;
                        _applyFilters();
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(value: 'semua', child: Text('Semua Kategori')),
                      const PopupMenuDivider(),
                      ..._kategoriList.map((String kategori) {
                        return PopupMenuItem<String>(value: kategori, child: Text(kategori));
                      }).toList(),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.filter_list, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedKategori != null && _toggleSelections[1])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Kategori: $_selectedKategori'),
                  onDeleted: () {
                    setState(() {
                      _selectedKategori = null;
                      _applyFilters();
                    });
                  },
                  backgroundColor: const Color.fromARGB(255, 219, 244, 255),
                  deleteIconColor: const Color.fromARGB(255, 227, 0, 0),
                ),
              ),
            ),
          Expanded(
            child: _toggleSelections[0]
                ? _buildManualInputPad()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredBarangList.isEmpty
                        ? Center(child: Text('Tidak ada barang ditemukan.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                        : RefreshIndicator(
                            onRefresh: _fetchInitialData,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 5),
                              itemCount: _filteredBarangList.length,
                              itemBuilder: (context, index) {
                                final barang = _filteredBarangList[index];
                                final initial = (barang['nama_barang']?.isNotEmpty ?? false) ? barang['nama_barang'][0].toUpperCase() : '?';
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF00A0E3),
                                      child: Text(initial, style: TextStyle(color: const Color.fromARGB(255, 244, 252, 255), fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(barang['nama_barang'] ?? 'N/A'),
                                    subtitle: Text('Stok: ${barang['stok_barang'] ?? 0} | Rp ${barang['harga_jual'] ?? 0}'),
                                    onTap: () {
                                      double itemPrice = double.tryParse(barang['harga_jual']?.toString() ?? '0.0') ?? 0.0;
                                      _addItemToTransaction(
                                        name: barang['nama_barang'] ?? 'Unknown Item',
                                        price: itemPrice,
                                        itemId: barang['id']?.toString(),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          if (_showPayBar)
            GestureDetector(
              onTap: _handlePay,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                color: const Color(0xFF00A0E3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bayar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rp ${_transactionTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualInputPad() {
    // ... (Fungsi _buildManualInputPad dari kode asli Anda tidak perlu diubah)
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Rp $_currentManualAmount',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final List<String> buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '000', 'C'];
                return InkWell(
                  onTap: () => _updateManualInput(buttons[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(child: Text(buttons[index], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    double manualAmount = double.tryParse(_currentManualAmount) ?? 0.0;
                    if (manualAmount > 0) {
                      _addItemToTransaction(name: 'Manual Input', price: manualAmount, itemId: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}');
                      setState(() {
                        _manualInputController.clear();
                        _currentManualAmount = "0";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A0E3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Tambah', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: ElevatedButton(
                  onPressed: () => _updateManualInput('DEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Icon(Icons.backspace_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}