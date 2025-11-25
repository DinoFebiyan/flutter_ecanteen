import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kantin Poliwangi',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // PENTING: Referensi ke koleksi di Firebase
  final CollectionReference _menuRef =
      FirebaseFirestore.instance.collection('menus');

  final CollectionReference _orderRef =
      FirebaseFirestore.instance.collection('orders');

  String selectedCategory = 'Makanan'; //category default

  // Helper: Mengubah angka menjadi format Rupiah
  String formatRupiah(int price) {
    return NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
    ).format(price);
  }

  void _showOrderDialog(String menuName, int price) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Pesan $menuName"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Nama Pemesan",
            hintText: "Contoh: Budi (TI-2A)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // LOGIKA UPLOAD DATA KE FIRESTORE
                _orderRef.add({
                  'menu_item': menuName,
                  'price': price,
                  'customer_name': nameController.text,
                  'status': 'Menunggu',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pesanan berhasil dikirim!")),
                );
              }
            },
            child: const Text("Pesan Sekarang"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E-Canteen Poliwangi")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = 'Makanan';
                  });
                },
                child: const Text('Makanan'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = 'Minuman';
                  });
                },
                child: const Text('Minuman'),
              ),
            ],
          ),
          const SizedBox(height: 10),
            Expanded(child: StreamBuilder(
              stream: _menuRef.where('category', isEqualTo: selectedCategory).snapshots(), // Mendengarkan koleksi 'menus'
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // 1. Handling Error
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan koneksi."));
                }

                // 2. Handling Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Handling Data Kosong
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Menu belum tersedia."));
                }

                // 4. Menampilkan Data
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    // Casting data agar aman
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text(data['name'][0]), // Huruf pertama
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formatRupiah(data['price'] ?? 0)),
                        trailing: ElevatedButton(
                          onPressed: data['isAvailable'] == true
                              ? () => _showOrderDialog(data['name'], data['price'])
                              : null, // Disable jika tidak available
                          child: Text(data['isAvailable'] ? "Pesan" : "Habis"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
