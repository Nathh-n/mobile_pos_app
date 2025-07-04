import 'package:flutter/material.dart';
import 'edit_barang_page.dart'; // <-- DITAMBAHKAN: Import halaman edit

class DetailBarangPage extends StatelessWidget {
  final Map<String, dynamic> barang;
  const DetailBarangPage({super.key, required this.barang});

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? namaBarang = barang['nama_barang'];
    final String initial = namaBarang != null && namaBarang.isNotEmpty
        ? namaBarang[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF00A0E3),
                    child: Text(initial, style: TextStyle(fontSize: 40, color: const Color.fromARGB(255, 241, 251, 255), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(barang['nama_barang'] ?? 'Nama Barang Tidak Tersedia', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4.0),
                      Text('${barang['stok_barang'] ?? '0'} stok', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),
            _buildDetailRow('Kode Barang', barang['kode_barang'] ?? '-'),
            _buildDetailRow('Harga Modal', 'Rp ${barang['harga_modal'] ?? '0'}'),
            _buildDetailRow('Harga Jual', 'Rp ${barang['harga_jual'] ?? '0'}'),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                // =================================================================
                // PERUBAHAN UTAMA: Logika tombol 'Ubah' ditambahkan di sini
                // =================================================================
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBarangPage(barang: barang),
                    ),
                  ).then((berhasilUpdate) {
                    // Ini akan dieksekusi setelah halaman edit ditutup.
                    // Jika halaman edit mengirim sinyal 'true', maka kita tutup juga halaman detail
                    // agar halaman gudang bisa me-refresh datanya.
                    if (berhasilUpdate == true) {
                      Navigator.pop(context, true); // Kirim sinyal refresh ke gudang_home_page
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: const Color(0xFF00A0E3)),
                ),
                child: const Text('Ubah'),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A0E3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
