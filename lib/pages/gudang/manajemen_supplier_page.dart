import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManajemenSupplierPage extends StatefulWidget {
  const ManajemenSupplierPage({super.key});

  @override
  State<ManajemenSupplierPage> createState() => _ManajemenSupplierPageState();
}

class _ManajemenSupplierPageState extends State<ManajemenSupplierPage> {
  List _supplierList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }


  Future<void> _fetchSuppliers() async {
    setState(() { _isLoading = true; });
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_supplier.php';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _supplierList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _addSupplier(String nama, String telepon) async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/tambah_supplier.php';
    await _handleApiRequest(apiUrl, {'nama_supplier': nama, 'no_telepon': telepon}, 'Supplier berhasil ditambahkan');
  }

  Future<void> _editSupplier(int id, String nama, String telepon) async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/edit_supplier.php';
    await _handleApiRequest(apiUrl, {'id': id, 'nama_supplier': nama, 'no_telepon': telepon}, 'Supplier berhasil diperbarui');
  }

  Future<void> _deleteSupplier(int id) async {
    const String apiUrl = 'http://192.168.89.181/api_flutter/hapus_supplier.php';
    await _handleApiRequest(apiUrl, {'id': id}, 'Supplier berhasil dihapus');
  }

  Future<void> _handleApiRequest(String url, Map<String, dynamic> body, String successMessage) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );
      if (!mounted) return;
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? successMessage), backgroundColor: Colors.green),
        );
        _fetchSuppliers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${responseData['message']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }


  void _showFormDialog({Map<String, dynamic>? supplier}) {
    final bool isEditing = supplier != null;
    final namaController = TextEditingController(text: isEditing ? supplier['nama_supplier'] : '');
    final teleponController = TextEditingController(text: isEditing ? supplier['no_telepon'] : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Supplier' : 'Tambah Supplier Baru'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Supplier'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: teleponController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon (Opsional)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (isEditing) {
                    _editSupplier(int.parse(supplier['id'].toString()), namaController.text, teleponController.text);
                  } else {
                    _addSupplier(namaController.text, teleponController.text);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int id, String nama) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus supplier "$nama"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                _deleteSupplier(id);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Supplier')),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSuppliers,
              child: _supplierList.isEmpty
              ? const Center(child: Text("Belum ada supplier. Silakan tambahkan."))
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _supplierList.length,
                itemBuilder: (context, index) {
                  final supplier = _supplierList[index];
                  final noTelepon = supplier['no_telepon'];
                  final bool hasTelepon = noTelepon != null && noTelepon.isNotEmpty;

                  return Card(
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, top: 10, bottom: 10, right: 0),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00A0E3),
                        child: Text(
                          supplier['nama_supplier'][0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 242, 254, 255)),
                        ),
                      ),
                      title: Text(supplier['nama_supplier'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        hasTelepon ? noTelepon : 'No. Telepon tidak ada',
                        style: TextStyle(
                          color: hasTelepon ? Colors.black54 : Colors.grey,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showFormDialog(supplier: supplier);
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(int.parse(supplier['id'].toString()), supplier['nama_supplier']);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus', style: TextStyle(color: Colors.red))),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        label: const Text('Supplier'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00A0E3),
        foregroundColor: Colors.white,
      ),
    );
  }
}
