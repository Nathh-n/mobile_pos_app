import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

class BuatPesananPage extends StatefulWidget {
  const BuatPesananPage({super.key});

  @override
  State<BuatPesananPage> createState() => _BuatPesananPageState();
}

class _BuatPesananPageState extends State<BuatPesananPage> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedSupplierId;
  DateTime _selectedDate = DateTime.now();
  final _nomorPoController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _supplierList = [];
  bool _isLoading = false;
  bool _isSupplierLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_supplier.php';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _supplierList = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _isSupplierLoading = false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // --- LOGIKA TAMBAH BARANG ---
  void _addItem() async {
    // 1. Buka dialog pencarian barang
    final selectedBarang = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const SearchBarangDialog(),
    );

    if (selectedBarang != null) {
      // 2. Jika barang terpilih, buka dialog untuk input jumlah & harga
      final itemDetails = await _showInputJumlahDialog(context, selectedBarang);
      
      if (itemDetails != null) {
        // 3. Tambahkan barang ke daftar sementara
        setState(() {
          _items.add({
            'id_barang': selectedBarang['id'],
            'nama_barang': selectedBarang['nama_barang'],
            'jumlah': itemDetails['jumlah'],
            'harga_beli': itemDetails['harga_beli'],
          });
        });
      }
    }
  }

  // Dialog untuk input jumlah dan harga beli
  Future<Map<String, dynamic>?> _showInputJumlahDialog(BuildContext context, Map<String, dynamic> barang) async {
    final jumlahController = TextEditingController();
    final hargaController = TextEditingController(text: barang['harga_modal']?.toString() ?? '0');
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(barang['nama_barang']),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Masukkan jumlah valid' : null,
                ),
                TextFormField(
                  controller: hargaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Harga Beli Satuan'),
                  validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Masukkan harga valid' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'jumlah': int.parse(jumlahController.text),
                    'harga_beli': double.parse(hargaController.text),
                  });
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _simpanPesanan() async {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      setState(() { _isLoading = true; });

      final dataToSend = {
        'id_supplier': _selectedSupplierId,
        'nomor_po': _nomorPoController.text,
        'tanggal_pesanan': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'items': _items.map((item) => {
            'id_barang': item['id_barang'],
            'jumlah': item['jumlah'],
            'harga_beli': item['harga_beli']
        }).toList()
      };

      const String apiUrl = 'http://192.168.89.181/api_flutter/buat_pesanan.php';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(dataToSend),
        );
        if (!mounted) return;
        final responseData = jsonDecode(response.body);

        if(response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green,));
            Navigator.pop(context, true);
        } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${responseData['message']}"), backgroundColor: Colors.red,));
        }
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi Error: $e"), backgroundColor: Colors.red,));
      } finally {
          setState(() { _isLoading = false; });
      }

    } else if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap tambahkan minimal satu barang.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Pesanan Baru")),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isSupplierLoading) const Center(child: CircularProgressIndicator())
                  else DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    hint: const Text("Pilih Supplier"),
                    isExpanded: true,
                    items: _supplierList.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier['id'].toString(),
                        child: Text(supplier['nama_supplier']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() { _selectedSupplierId = value; }),
                    validator: (value) => value == null ? 'Supplier harus dipilih' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomorPoController,
                    decoration: const InputDecoration(labelText: 'Nomor PO / Faktur (Opsional)'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text("Tanggal Pesanan"),
                    subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Item Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text("Tambah")),
                    ],
                  ),
                  const SizedBox(height: 8),
                   _items.isEmpty
                   ? const Padding(padding: EdgeInsets.all(16.0), child: Text("Belum ada barang ditambahkan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                   : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                                child: ListTile(
                                    title: Text(item['nama_barang']),
                                    subtitle: Text("${item['jumlah']} Pcs @ Rp ${NumberFormat('#,##0', 'id_ID').format(item['harga_beli'])}"),
                                    trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => setState(() => _items.removeAt(index)),
                                    ),
                                ),
                            );
                        },
                   )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPesanan,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A0E3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Pesanan"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DIALOG PENCARIAN BARANG ---
class SearchBarangDialog extends StatefulWidget {
  const SearchBarangDialog({super.key});

  @override
  State<SearchBarangDialog> createState() => _SearchBarangDialogState();
}

class _SearchBarangDialogState extends State<SearchBarangDialog> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        setState(() { _searchResults = []; });
        return;
      }
      setState(() { _isSearching = true; });

      const String apiUrl = 'http://192.168.89.181/api_flutter/cari_barang.php';
      try {
        final response = await http.get(Uri.parse('$apiUrl?search=$query'));
        if (response.statusCode == 200) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          });
        }
      } catch (e) {
        // Handle error
      } finally {
        setState(() { _isSearching = false; });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cari Barang'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ketik nama barang...',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching) const CircularProgressIndicator(),
            if (!_isSearching && _searchResults.isEmpty) const Text('Tidak ada hasil.'),
            if (!_isSearching && _searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final barang = _searchResults[index];
                    return ListTile(
                      title: Text(barang['nama_barang']),
                      onTap: () {
                        // Kembalikan data barang yang dipilih
                        Navigator.of(context).pop(barang);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
    );
  }
}
