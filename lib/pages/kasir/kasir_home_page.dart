import 'package:flutter/material.dart';
import 'transaksi_page.dart';
import 'riwayat_transaksi_page.dart';
import 'laporan_penjualan_page.dart';
import 'menu_kasir_page.dart';

class KasirHomePage extends StatefulWidget {
  const KasirHomePage({super.key});

  @override
  State<KasirHomePage> createState() => _KasirHomePageState();
}

class _KasirHomePageState extends State<KasirHomePage> {
  int _selectedIndex = 0;

  // 2. Ganti placeholder dengan halaman yang sebenarnya
  static const List<Widget> _widgetOptions = <Widget>[
    TransaksiPage(),
    RiwayatTransaksiPage(),
    LaporanTransaksiPage(),
    MenuKasirPage(), // <-- Gunakan MenuKasirPage
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00A0E3),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
