import 'package:flutter/material.dart';
import 'barang_page.dart';
import 'pembelian_page.dart';
import 'laporan_page.dart'; // <-- 1. Impor LaporanPage
import 'menu_page.dart';      // <-- 2. Impor MenuPage

class GudangHomePage extends StatefulWidget {
  const GudangHomePage({super.key});

  @override
  State<GudangHomePage> createState() => _GudangHomePageState();
}

class _GudangHomePageState extends State<GudangHomePage> {
  int _selectedIndex = 0;

  // 3. Ganti placeholder dengan widget halaman yang sebenarnya
  static const List<Widget> _widgetOptions = <Widget>[
    BarangPage(),       // Index 0
    PembelianPage(),    // Index 1
    LaporanPage(),      // Index 2
    MenuPage(),         // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan berganti sesuai dengan pilihan di navigasi
      // IndexedStack menjaga state setiap halaman agar tidak hilang saat berpindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      // BottomNavigationBar menjadi satu-satunya navigasi utama
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Barang'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Pembelian'), // Ikon disesuaikan
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Laporan'),   // Ikon disesuaikan
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00A0E3),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Penting agar semua label terlihat
      ),
    );
  }
}
