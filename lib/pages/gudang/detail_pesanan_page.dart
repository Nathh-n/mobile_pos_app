import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class DetailPesananPage extends StatefulWidget {
  final dynamic idPembelian;
  const DetailPesananPage({super.key, required this.idPembelian});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  Map<String, dynamic>? _pesananDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false; // Untuk proses Terima Barang
  bool _isCancelling = false; // <-- State baru untuk proses Batal

  @override
  void initState() {
    super.initState();
    _fetchDetailPesanan();
  }

  Future<void> _fetchDetailPesanan() async {
    // ... (Fungsi ini tidak berubah)
    setState(() { _isLoading = true; _errorMessage = null; });
    const String apiUrl = 'http://192.168.89.181/api_flutter/ambil_detail_pesanan.php';
    try {
      final response = await http.post( Uri.parse(apiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: jsonEncode({'id_pembelian': widget.idPembelian}), );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() { _pesananDetail = jsonDecode(response.body); });
      } else {
        setState(() { _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memuat data.'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = 'Terjadi kesalahan: $e'; });
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _sharePesanan() {
    // ... (Fungsi ini tidak berubah)
    if (_pesananDetail == null) return;
    String header = "Yth. ${_pesananDetail!['nama_supplier'] ?? 'Supplier'},\n\n";
    header += "Kami ingin memesan barang (PO: ${_pesananDetail!['nomor_po']}) dengan rincian:\n\n";
    String itemList = "";
    for (var item in (_pesananDetail!['items'] as List)) {
        itemList += "- ${item['nama_barang']} (${item['jumlah']} Pcs)\n";
    }
    String footer = "\nMohon untuk segera diproses. Terima kasih.";
    Share.share(header + itemList + footer);
  }
  
  // --- FUNGSI BARU UNTUK MEMBATALKAN PESANAN ---
  Future<void> _batalkanPesanan() async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text('Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat diurungkan.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) return;

    setState(() { _isCancelling = true; });

    const String apiUrl = 'http://192.168.89.181/api_flutter/batalkan_pesanan.php';
    
    try {
        final response = await http.post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'id_pembelian': widget.idPembelian.toString()})
        );
        if(!mounted) return;
        final responseData = jsonDecode(response.body);

        if(response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green,));
            Navigator.pop(context, true); // Kirim sinyal refresh
        } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${responseData['message']}"), backgroundColor: Colors.red,));
        }
    } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi error: $e"), backgroundColor: Colors.red,));
    } finally {
        if(mounted) setState(() { _isCancelling = false; });
    }
  }

  Future<void> _terimaBarang() async {
    // ... (Fungsi ini tidak berubah, hanya on-pressed nya disesuaikan)
     final bool? konfirmasi = await showDialog<bool>( context: context, builder: (BuildContext context) { return AlertDialog( title: const Text('Konfirmasi Penerimaan'), content: const Text('Apakah Anda yakin ingin menerima barang ini? Stok akan otomatis ditambahkan.'), actions: <Widget>[ TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal'),), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Terima'),),],);},);
    if (konfirmasi != true) return;
    setState(() { _isProcessing = true; });
    const String apiUrl = 'http://192.168.89.181/api_flutter/terima_barang.php';
    try {
        final response = await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: jsonEncode({'id_pembelian': widget.idPembelian.toString()}));
        if(!mounted) return;
        final responseData = jsonDecode(response.body);
        if(response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green,));
            Navigator.pop(context, true); 
        } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${responseData['message']}"), backgroundColor: Colors.red,));
        }
    } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi error: $e"), backgroundColor: Colors.red,));
    } finally {
        if(mounted) setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Widget build utama tidak berubah)
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pesanan"), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 1,),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildBody() {
    // ... (Widget _buildBody tidak berubah)
     if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    if (_errorMessage != null || _pesananDetail == null) { return Center(child: Text(_errorMessage ?? "Data tidak ditemukan")); }
    final detail = _pesananDetail!;
    final items = detail['items'] as List;
    final totalHarga = items.fold(0.0, (sum, item) => sum + (double.parse(item['jumlah'].toString()) * double.parse(item['harga_beli'].toString())));
    return ListView( padding: const EdgeInsets.all(16), children: [ _buildStatusChip(detail['status']), const SizedBox(height: 16), Text(detail['nama_supplier'] ?? 'Tanpa Supplier', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("Nomor PO: ${detail['nomor_po'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey)), Text("Tanggal Pesan: ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(detail['tanggal_pesanan']))}", style: const TextStyle(color: Colors.grey)), const Divider(height: 32), const Text("Rincian Barang:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8), ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; final subtotal = double.parse(item['jumlah'].toString()) * double.parse(item['harga_beli'].toString()); return Card( margin: const EdgeInsets.only(bottom: 8), child: ListTile( title: Text(item['nama_barang']), subtitle: Text('${item['jumlah']} Pcs x Rp ${NumberFormat('#,##0', 'id_ID').format(double.parse(item['harga_beli']))}'), trailing: Text('Rp ${NumberFormat('#,##0', 'id_ID').format(subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold)),),);},), const Divider(height: 32), Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Total Pembelian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text('Rp ${NumberFormat('#,##0', 'id_ID').format(totalHarga)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan)),],),],);
  }

  // --- WIDGET INI DIUBAH TOTAL UNTUK LAYOUT BARU ---
  Widget? _buildBottomButtons() {
    if (_isLoading || _pesananDetail == null || _pesananDetail!['status'] != 'Dipesan') {
      return null;
    }
    
    // Gunakan Column untuk menumpuk baris tombol dan tombol bagikan
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Agar column tidak memenuhi layar
          children: [
            // Baris pertama untuk tombol Batal dan Terima
            Row(
              children: [
                // Tombol Batalkan Pesanan (background merah)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || _isCancelling ? null : _batalkanPesanan,
                    icon: _isCancelling
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Icon(Icons.cancel_outlined),
                    label: Text(_isCancelling ? "Membatalkan..." : "Batalkan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol Terima Barang (background hijau)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || _isCancelling ? null : _terimaBarang,
                    icon: _isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isProcessing ? "Memproses..." : "Terima Barang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Jarak antara baris tombol
            // Tombol Bagikan di bawahnya
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessing || _isCancelling ? null : _sharePesanan,
                icon: const Icon(Icons.share_outlined),
                label: const Text("Bagikan Pesanan"),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  foregroundColor: Theme.of((context)).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatusChip(String? status) {
    // ... (Widget ini tidak berubah)
    Color chipColor = Colors.grey; String chipText = 'Unknown'; IconData chipIcon = Icons.help_outline;
    switch (status) { case 'Dipesan': chipColor = Colors.orange; chipText = 'Dipesan'; chipIcon = Icons.pending_actions; break; case 'Selesai': chipColor = Colors.green; chipText = 'Selesai'; chipIcon = Icons.check_circle; break; case 'Dibatalkan': chipColor = Colors.red; chipText = 'Batal'; chipIcon = Icons.cancel; break; }
    return Align( alignment: Alignment.centerLeft, child: Container( padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration( color: chipColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20),), child: Row( mainAxisSize: MainAxisSize.min, children: [ Icon(chipIcon, color: chipColor, size: 16), const SizedBox(width: 6), Text(chipText, style: TextStyle(color: chipColor, fontWeight: FontWeight.bold)),],),),);
  }
}