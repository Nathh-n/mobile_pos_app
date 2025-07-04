import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final TextEditingController _kategoriNameController = TextEditingController();
  List _kategoriList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
  }

  @override
  void dispose() {
    _kategoriNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchKategori() async {
    setState(() { _isLoading = true; });
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_kategori.php';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _kategoriList = data['records'] ?? [];
        });
      } else if (response.statusCode == 404) {
        setState(() { _kategoriList = []; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching categories: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _addKategori() async {
    if (_kategoriNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kategori tidak boleh kosong.')));
      return;
    }

    setState(() { _isLoading = true; });
    const String apiUrl = 'http://192.168.89.181/api_flutter/simpan_kategori.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'nama_kategori': _kategoriNameController.text}),
      ).timeout(const Duration(seconds: 10));

      // DEBUGGING CODE START
      print("Response dari server: ${response.body}"); // Menampilkan respons mentah
      final responseData;
      try {
        responseData = jsonDecode(response.body); // Mencoba decode JSON
        print("Kategori berhasil ditambah: $responseData"); // Menampilkan data setelah decode
      } catch (e) {
        print("JSON decode error: $e"); // Menangkap error decode JSON
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mengurai respons server: $e')));
        setState(() { _isLoading = false; });
        return; // Hentikan eksekusi jika gagal decode
      }
      // DEBUGGING CODE END

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
        _kategoriNameController.clear();
        await _fetchKategori(); // Refresh list
        Navigator.pop(context, true); // Signal success and pop back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'] ?? 'Gagal menambahkan kategori.')));
      }
    } catch (e) {
      // Ini akan menangkap error jaringan atau timeout
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        backgroundColor: const Color(0xFF00A0E3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kategoriNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kategori Baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _addKategori,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A0E3),
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _kategoriList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _kategoriList.isEmpty
                    ? const Center(child: Text('Tidak ada kategori.'))
                    : ListView.builder(
                        itemCount: _kategoriList.length,
                        itemBuilder: (context, index) {
                          final kategori = _kategoriList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(kategori['nama_kategori']),
                              // You might add edit/delete functionality here later
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
