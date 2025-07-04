import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:tes_capston/pages/kategori/kategori_page.dart';


class TambahBarangPage extends StatefulWidget {
  const TambahBarangPage({super.key});

  @override
  State<TambahBarangPage> createState() => _TambahBarangPageState();
}

class _TambahBarangPageState extends State<TambahBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaBarangController = TextEditingController();
  final _stokController = TextEditingController();
  final _hargaModalController = TextEditingController();
  final _kodeBarangController = TextEditingController();
  final _namaHargaController = TextEditingController(text: 'Eceran');
  final _hargaJualController = TextEditingController();

  final TextEditingController _selectedKategoriNameController = TextEditingController();
  String? _selectedKategoriId;

  bool _isLoading = false;
  bool _dataHasChanged = false;

  @override
  void dispose() {
    _namaBarangController.dispose();
    _stokController.dispose();
    _hargaModalController.dispose();
    _kodeBarangController.dispose();
    _namaHargaController.dispose();
    _hargaJualController.dispose();
    _selectedKategoriNameController.dispose();
    super.dispose();
  }

  Future<bool> _handleApiSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      const String apiUrl = 'http://192.168.89.181/api_flutter/simpan_barang.php';
      bool success = false;

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'nama_barang': _namaBarangController.text,
            'stok_awal': _stokController.text,
            'harga_modal': _hargaModalController.text,
            'kode_barang': _kodeBarangController.text,
            'id_kategori': _selectedKategoriId,
            'nama_harga': _namaHargaController.text,
            'harga_jual': _hargaJualController.text,
          }),
        ).timeout(const Duration(seconds: 10));
        
        if (!mounted) return false;
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'] ?? 'Barang berhasil disimpan')));
          success = true;
          _dataHasChanged = true;
        } else {
           String errorMessage = responseData['message'] ?? 'Terjadi kesalahan tidak diketahui.';
           if (responseData['error'] != null) {
              errorMessage += "\nDetail: ${responseData['error']}";
           }
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), duration: const Duration(seconds: 5)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
      } finally {
        setState(() { _isLoading = false; });
      }
      return success;
    }
    return false;
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    _namaBarangController.clear();
    _stokController.clear();
    _hargaModalController.clear();
    _kodeBarangController.clear();
    _namaHargaController.text = 'Eceran';
    _hargaJualController.clear();
    setState(() {
      _selectedKategoriNameController.clear();
      _selectedKategoriId = null;
    });
  }

  Future<void> _simpan() async {
    final isSuccess = await _handleApiSave();
    if (isSuccess && mounted) {
      Navigator.pop(context, _dataHasChanged);
    }
  }

  Future<void> _simpanDanBuatLagi() async {
    final isSuccess = await _handleApiSave();
    if (isSuccess) {
      _resetForm();
    }
  }

  // Perbaikan pada fungsi _showKategoriSelectionDialog
  Future<void> _showKategoriSelectionDialog() async {
    List _kategoriList = [];
    bool dialogIsLoading = true; // State awal untuk loading dialog

    // Fungsi ini sekarang menerima 'setDialogState' sebagai parameter
    Future<void> fetchKategoriDialog(StateSetter setDialogStateCallback) async {
      setDialogStateCallback(() { // Update state of the dialog
        dialogIsLoading = true;
        _kategoriList = []; // Clear list while loading
      });

      const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_kategori.php';
      try {
        final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setDialogStateCallback(() { // Update state of the dialog
            _kategoriList = data['records'] ?? [];
            dialogIsLoading = false;
          });
        } else if (response.statusCode == 404) {
          setDialogStateCallback(() {
            _kategoriList = [];
            dialogIsLoading = false;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}')));
          }
          setDialogStateCallback(() { dialogIsLoading = false; }); // Pastikan loading state direset
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching categories: $e')));
        }
        setDialogStateCallback(() { dialogIsLoading = false; }); // Pastikan loading state direset
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Panggil fetchKategoriDialog saat dialog pertama kali dibangun
            // atau saat perlu direfresh (misalnya setelah menambahkan kategori baru)
            if (dialogIsLoading) { // Hanya panggil fetch jika sedang loading (atau perlu refresh)
              fetchKategoriDialog(setDialogState);
            }

            return AlertDialog(
              title: const Text('Pilih Kategori'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Berikan tinggi tetap agar Expanded tidak error saat _kategoriList kosong
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    dialogIsLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )
                        : _kategoriList.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Tidak ada kategori. Tambahkan kategori baru.'),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _kategoriList.length,
                                  itemBuilder: (context, index) {
                                    final kategori = _kategoriList[index];
                                    return ListTile(
                                      title: Text(kategori['nama_kategori']),
                                      onTap: () {
                                        setState(() { // Update state of TambahBarangPage
                                          _selectedKategoriNameController.text = kategori['nama_kategori'];
                                          _selectedKategoriId = kategori['id'].toString();
                                        });
                                        Navigator.pop(dialogContext); // Close dialog
                                      },
                                    );
                                  },
                                ),
                              ),
                    const Divider(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          dialogContext,
                          MaterialPageRoute(builder: (context) => const KategoriPage()),
                        );
                        if (result == true) { // Jika kategori baru berhasil ditambahkan
                          // Reset dialogIsLoading to true to trigger re-fetch on next build cycle
                          // and call fetchKategoriDialog to update the dialog's state
                          await fetchKategoriDialog(setDialogState);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kategori Baru'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A0E3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dataHasChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tambah Barang')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 24),
              _buildTextFormField(controller: _namaBarangController, label: 'Nama Barang (Wajib)'),
              _buildTextFormField(controller: _stokController, label: 'Stok Awal (Wajib)', keyboardType: TextInputType.number),
              _buildTextFormField(controller: _hargaModalController, label: 'Harga Modal', keyboardType: TextInputType.number),
              _buildTextFormField(controller: _kodeBarangController, label: 'Kode Barang'),
              // Kategori selection using TextFormField and custom dialog
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _selectedKategoriNameController,
                  readOnly: true, // Make it read-only
                  onTap: _showKategoriSelectionDialog, // Show dialog on tap
                  decoration: const InputDecoration(
                    labelText: 'Kategori (Opsional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down), // Dropdown icon
                  ),
                  validator: (value) {
                    // Optional validation for category
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Harga Jual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: _buildTextFormField(controller: _namaHargaController, label: 'Nama Harga (Wajib)')), const SizedBox(width: 16), Expanded(child: _buildTextFormField(controller: _hargaJualController, label: 'Harga', keyboardType: TextInputType.number))]),
              const SizedBox(height: 32),
              Row(children: [Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _simpan, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A0E3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Simpan'))), const SizedBox(width: 16), Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _simpanDanBuatLagi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A0E3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Simpan & buat lagi')))]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        validator: (value) {
          if (label.contains('(Wajib)') && (value == null || value.isEmpty)) {
            return '$label tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }
}