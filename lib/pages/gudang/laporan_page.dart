import 'package:flutter/material.dart';
import 'laporan_stok_barang_page.dart';
import 'laporan_pembelian_page.dart'; // 1. Impor halaman laporan pembelian

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.inventory_2_outlined,
            title: 'Laporan Stok Barang',
            subtitle: 'Lihat ringkasan stok masuk dan keluar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LaporanStokBarangPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          // --- TOMBOL BARU DI SINI ---
          _buildMenuItem(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'Laporan Pembelian',
            subtitle: 'Lihat riwayat pembelian dari supplier',
            onTap: () {
              // 2. Navigasi ke halaman laporan pembelian
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LaporanPembelianPage()),
              );
            },
          ),
          // --- AKHIR TOMBOL BARU ---
        ],
      ),
    );
  }

  // Mengganti nama _buildReportCard menjadi _buildMenuItem agar lebih konsisten
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00A0E3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color.fromARGB(255, 247, 253, 255), size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
