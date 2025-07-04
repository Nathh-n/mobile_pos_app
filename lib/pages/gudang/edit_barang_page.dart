import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class EditBarangPage extends StatefulWidget {
  final Map<String, dynamic> barang;
  const EditBarangPage({super.key, required this.barang});

  @override
  State<EditBarangPage> createState() => _EditBarangPageState();
}

class _EditBarangPageState extends State<EditBarangPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaBarangController;
  // REVISI: Hapus controller untuk stok
  // late TextEditingController _stokController; 
  late TextEditingController _hargaModalController;
  late TextEditingController _kodeBarangController;
  late TextEditingController _namaHargaController;
  late TextEditingController _hargaJualController;

  String? _selectedKategoriId;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _namaBarangController = TextEditingController(text: widget.barang['nama_barang']);
    // REVISI: Hapus inisialisasi controller stok
    // _stokController = TextEditingController(text: widget.barang['stok_barang'].toString());
    _hargaModalController = TextEditingController(text: widget.barang['harga_modal']?.toString() ?? '0');
    _kodeBarangController = TextEditingController(text: widget.barang['kode_barang']);
    _namaHargaController = TextEditingController(text: widget.barang['nama_harga'] ?? 'Eceran');
    _hargaJualController = TextEditingController(text: widget.barang['harga_jual']?.toString() ?? '0');
    _selectedKategoriId = widget.barang['id_kategori']?.toString();
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    // REVISI: Hapus dispose controller stok
    // _stokController.dispose(); 
    _hargaModalController.dispose();
    _kodeBarangController.dispose();
    _namaHargaController.dispose();
    _hargaJualController.dispose();
    super.dispose();
  }

  Future<void> _showKonfirmasiHapus() async {
    // ... (Fungsi ini tidak berubah)
    return showDialog<void>( context: context, builder: (BuildContext context) { return AlertDialog( title: const Text('Konfirmasi Hapus'), content: Text('Anda yakin ingin menghapus barang "${widget.barang['nama_barang']}"?'), actions: <Widget>[ TextButton( child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(), ), ElevatedButton( style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _isDeleting ? null : _hapusBarang, child: _isDeleting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Hapus', style: TextStyle(color: Colors.white)), ), ], ); }, );
  }

  Future<void> _hapusBarang() async {
    // ... (Fungsi ini tidak berubah)
    setState(() { _isDeleting = true; }); const String apiUrl = 'http://192.168.89.181/api_flutter/hapus_barang.php'; try { final response = await http.post( Uri.parse(apiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: jsonEncode({'id_barang': widget.barang['id'].toString()}), ).timeout(const Duration(seconds: 15)); if (!mounted) return; final responseData = jsonDecode(response.body); Navigator.of(context).pop(); if (response.statusCode == 200) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']))); Navigator.of(context).pop(true); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${responseData['message']}"))); } } catch (e) { if (!mounted) return; Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e'))); } finally { if (mounted) setState(() { _isDeleting = false; }); }
  }

  Future<void> _simpanPerubahan() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      const String apiUrl = 'http://192.168.89.181/api_flutter/edit_barang.php';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'id_barang': widget.barang['id'].toString(),
            'nama_barang': _namaBarangController.text,
            'harga_modal': _hargaModalController.text,
            'kode_barang': _kodeBarangController.text,
            'id_kategori': _selectedKategoriId,
            'nama_harga': _namaHargaController.text,
            'harga_jual': _hargaJualController.text,
          })
        );

        if (!mounted) return;
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));
          Navigator.pop(context, true);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${responseData['message']}")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Barang'),
        // REVISI: Tombol hapus dipindahkan dari AppBar
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _namaBarangController, decoration: const InputDecoration(labelText: 'Nama Barang (Wajib)'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 16),
            // REVISI: Hapus TextFormField untuk Stok Awal
            // TextFormField(controller: _stokController, decoration: const InputDecoration(labelText: 'Stok Awal (Wajib)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            // const SizedBox(height: 16),
            TextFormField(controller: _hargaModalController, decoration: const InputDecoration(labelText: 'Harga Modal'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextFormField(controller: _kodeBarangController, decoration: const InputDecoration(labelText: 'Kode Barang')),
            const SizedBox(height: 24),
            const Center(child: Text('Harga Jual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: TextFormField(controller: _namaHargaController, decoration: const InputDecoration(labelText: 'Nama Harga (Wajib)'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _hargaJualController, decoration: const InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number))]),
            const SizedBox(height: 32),
            
            // REVISI: Layout baru untuk tombol Simpan dan Hapus
            Row(
              children: [
                // Tombol Hapus (sekarang di kiri)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || _isDeleting) ? null : _showKonfirmasiHapus,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol Simpan (sekarang di kanan)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isDeleting) ? null : _simpanPerubahan,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: _isLoading ? const Text("Menyimpan...") : const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A0E3), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}