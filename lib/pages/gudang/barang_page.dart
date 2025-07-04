import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'tambah_barang_page.dart';
import 'detail_barang_page.dart';

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  bool _isLoading = true;
  List _barangList = [];
  List _filteredBarangList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSortedAscending = true;
  List<String> _kategoriList = [];
  String? _selectedKategori;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchBarang(),
      _fetchKategori(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchBarang() async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_barang.php';
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
      filteredList = filteredList.where((barang) => barang['nama_kategori'] == _selectedKategori).toList();
    }

    if (query.isNotEmpty) {
      filteredList = filteredList.where((barang) {
        return barang['nama_barang']?.toString().toLowerCase().contains(query) ?? false;
      }).toList();
    }

    setState(() => _filteredBarangList = filteredList);
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

  void _navigateToTambahBarang() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahBarangPage()),
    );
    if (result == true) {
      _fetchInitialData();
    }
  }

  void _navigateToDetailBarang(Map<String, dynamic> barang) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailBarangPage(barang: barang)),
    );
    if (result == true) {
      _fetchInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
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
                      padding: const EdgeInsets.all(12),
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
            if (_selectedKategori != null)
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
                    backgroundColor: Colors.cyan[50],
                    labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBarangList.isEmpty
                      ? const Center(child: Text('Tidak ada data barang.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _fetchInitialData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _filteredBarangList.length,
                            itemBuilder: (context, index) {
                              final barang = _filteredBarangList[index];
                              final String initial = (barang['nama_barang']?.isNotEmpty ?? false) ? barang['nama_barang'][0].toUpperCase() : '?';
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF00A0E3),
                                    child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 246, 254, 255))),
                                  ),
                                  title: Text(barang['nama_barang'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Stok: ${barang['stok_barang'] ?? 0} | Modal: Rp ${barang['harga_modal'] ?? 0}'),
                                  trailing: Text(barang['kode_barang'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  onTap: () => _navigateToDetailBarang(barang),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToTambahBarang,
        label: const Text('Barang'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00A0E3),
        foregroundColor: Colors.white,
      ),
    );
  }
}
