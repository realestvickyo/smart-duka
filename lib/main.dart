import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_mpesa_stk/flutter_mpesa_stk.dart';
import 'package:flutter_mpesa_stk/models/Mpesa.dart';
import 'package:flutter_mpesa_stk/models/MpesaResponse.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KimsDukaApp());
}

// --- APP CORE ---
class KimsDukaApp extends StatelessWidget {
  const KimsDukaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Kim's Duka",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade800, Colors.teal.shade600],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Kim's Duka",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your Business Partner",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MAIN NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey();

  void _refreshHome() {
    _homeKey.currentState?._refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(key: _homeKey),
      SalesScreen(onRefresh: _refreshHome),
      ProductsScreen(onRefresh: _refreshHome),
      ExpenseScreen(onRefresh: _refreshHome),
      const DebtScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Sell'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.money_off_csred_outlined), label: 'Expense'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Deni'),
        ],
      ),
    );
  }
}

// --- DATA MODELS ---
class Product {
  final String id, name, barcode;
  final int costPrice, sellingPrice;
  int stock;
  final int lowStockThreshold;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    this.barcode = "",
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'stock': stock,
    'barcode': barcode,
    'lowStockThreshold': lowStockThreshold
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    costPrice: json['costPrice'],
    sellingPrice: json['sellingPrice'],
    stock: json['stock'],
    barcode: json['barcode'] ?? "",
    lowStockThreshold: json['lowStockThreshold'] ?? 5,
  );
}

class Debt {
  final String id, customerName, phoneNumber;
  double totalAmount, paidAmount;
  final DateTime date;

  Debt({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.date,
  });

  double get remaining => totalAmount - paidAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phoneNumber': phoneNumber,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'date': date.toIso8601String()
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'],
    customerName: json['customerName'],
    phoneNumber: json['phoneNumber'] ?? "",
    totalAmount: (json['totalAmount'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
  );
}

class Expense {
  final String id, description, category;
  final int amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category = "General",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    description: json['description'],
    amount: json['amount'],
    date: DateTime.parse(json['date']),
    category: json['category'] ?? "General",
  );
}

class SaleItem {
  final Product product;
  int quantity;
  SaleItem({required this.product, this.quantity = 1});
}

// --- 1. DASHBOARD ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double cashSales = 0, mpesaSales = 0, grossProfit = 0, expenses = 0;
  List<Product> lowStockItems = [];
  bool _showProfit = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final expStr = prefs.getString('expenses_$today') ?? '[]';
    final List<dynamic> expJson = jsonDecode(expStr);
    final pStr = prefs.getString('products') ?? '[]';
    final List<Product> allProducts =
    (jsonDecode(pStr) as List).map((p) => Product.fromJson(p)).toList();

    setState(() {
      cashSales = prefs.getDouble('cash_sales_$today') ?? 0;
      mpesaSales = prefs.getDouble('mpesa_sales_$today') ?? 0;
      grossProfit = prefs.getDouble('profit_$today') ?? 0;
      expenses = expJson.fold(0.0, (sum, e) => sum + (e['amount'] as num));
      lowStockItems =
          allProducts.where((p) => p.stock <= p.lowStockThreshold).toList();
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pStr = prefs.getString('products') ?? '[]';
      final List products = jsonDecode(pStr);
      String csv = "Item Name,Stock,Buying Price,Selling Price\n";
      for (var p in products) {
        csv +=
        "${p['name']},${p['stock']},${p['costPrice']},${p['sellingPrice']}\n";
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          "${dir.path}/Inventory_${DateTime.now().millisecondsSinceEpoch}.csv");
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)],
          text: "Kim's Duka Inventory Report");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSales = cashSales + mpesaSales;
    double netProfit = grossProfit - expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kim's Duka"),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: _exportToCSV)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Net Profit Card with Toggleable Blur on Amount Only
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade800,
                        Colors.teal.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "NET PROFIT TODAY",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _showProfit
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showProfit = !_showProfit;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Amount with conditional blur
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The actual amount
                            Text(
                              "KES ${netProfit.toInt()}",
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Blur overlay when hidden
                            if (!_showProfit)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat("Revenue", "KES ${totalSales.toInt()}"),
                          _miniStat("Expenses", "KES ${expenses.toInt()}"),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              if (lowStockItems.isNotEmpty) _lowStockSection(),

              _statTile("Cash Transactions", cashSales, Colors.orange, Icons.attach_money),
              _statTile("M-Pesa Payments", mpesaSales, Colors.blue, Icons.smartphone),
              _statTile("Calculated Margin", grossProfit, Colors.green, Icons.trending_up),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _lowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("LOW STOCK ALERTS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12),
            itemCount: lowStockItems.length,
            itemBuilder: (c, i) => Card(
              color: Colors.red.shade50,
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(lowStockItems[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("${lowStockItems[i].stock} Left", style: const TextStyle(color: Colors.red)),
                    const Spacer(),
                    InkWell(
                      onTap: () => _sendWhatsAppOrder(lowStockItems[i].name),
                      child: const Text("Order Now", style: TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _sendWhatsAppOrder(String productName) async {
    final url = Uri.parse("whatsapp://send?text=Order request: $productName");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not installed')));
      }
    }
  }

  Widget _statTile(String title, double value, Color color, IconData icon) => ListTile(
    leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
    title: Text(title),
    trailing: Text("KES ${value.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}

// --- 2. SALES & POS WITH SEARCH ---
class SalesScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const SalesScreen({super.key, required this.onRefresh});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<SaleItem> cart = [];
  String paymentMode = "Cash";
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final pStr = prefs.getString('products') ?? '[]';
    setState(() {
      products = (jsonDecode(pStr) as List).map((p) => Product.fromJson(p)).toList();
      filteredProducts = products;
    });
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) => p.name.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _handleMpesa(double total) async {
    final phoneController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("M-Pesa Checkout"),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            hintText: "254712345678",
            labelText: "Phone Number",
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Send STK Push"),
          ),
        ],
      ),
    );

    if (result != true || phoneController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      FlutterMpesaSTK mpesa = FlutterMpesaSTK(
        "7TGG6CYQWlWULvk9XYES2UMGLOLxmhAto2tINvV5ICY056jP",
        "mHoVFAviw1C4ZHozjzDQySs9J4jUogZJalPb2OhI9ynl4eZ6e0mmuR3Zce5bpmop",
        "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
        "174379",
        "https://mpesa-callback-ten.vercel.app/api/mpesa-callback",
        "STK Push failed.",
        env: "sandbox",
      );

      MpesaResponse response = await mpesa.stkPush(
        Mpesa(
          total.toInt(),
          phoneController.text,
          accountReference: "Kim's Duka",
          transactionDesc: "Sale",
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.status
                ? "Payment prompt sent!"
                : "Error: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("M-Pesa Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!')),
      );
      return;
    }

    for (var item in cart) {
      final product = products.firstWhere((p) => p.id == item.product.id);
      if (product.stock < item.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough stock for ${item.product.name}'),
          ),
        );
        return;
      }
    }

    double total =
    cart.fold(0, (sum, it) => sum + (it.product.sellingPrice * it.quantity));

    if (paymentMode == "M-Pesa") {
      await _handleMpesa(total);
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double profit = cart.fold(
      0,
          (sum, it) => sum +
          ((it.product.sellingPrice - it.product.costPrice) * it.quantity),
    );

    String key =
    paymentMode == "Cash" ? 'cash_sales_$today' : 'mpesa_sales_$today';
    await prefs.setDouble(key, (prefs.getDouble(key) ?? 0) + total);
    await prefs.setDouble(
        'profit_$today', (prefs.getDouble('profit_$today') ?? 0) + profit);

    for (var it in cart) {
      products.firstWhere((p) => p.id == it.product.id).stock -= it.quantity;
    }
    await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList()));

    await _printReceipt(total);

    setState(() => cart.clear());
    widget.onRefresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _printReceipt(double total) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) => pw.Column(
            children: [
              pw.Text(
                "KIM'S DUKA",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.Divider(),
              ...cart.map(
                    (it) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("${it.product.name} x${it.quantity}"),
                    pw.Text("KES ${it.product.sellingPrice * it.quantity}"),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Text(
                "TOTAL KES ${total.toInt()}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Thank you for shopping!")
            ],
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result is String) {
      final product = products.where((p) => p.barcode == result).firstOrNull;
      if (product != null) {
        setState(() {
          final idx = cart.indexWhere((it) => it.product.id == product.id);
          if (idx != -1) {
            cart[idx].quantity++;
          } else {
            cart.add(SaleItem(product: product));
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} added to cart')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double total =
    cart.fold(0, (sum, it) => sum + (it.product.sellingPrice * it.quantity));

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Transaction"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Cart is empty', style: TextStyle(fontSize: 18)),
                  Text('Select products below to start'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (c, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(cart[i].product.name),
                  subtitle: Text(
                    "KES ${cart[i].product.sellingPrice} × ${cart[i].quantity}",
                  ),
                  trailing: Text(
                    "KES ${cart[i].product.sellingPrice * cart[i].quantity}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => setState(() {
                          if (cart[i].quantity > 1) {
                            cart[i].quantity--;
                          } else {
                            cart.removeAt(i);
                          }
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () => setState(() => cart[i].quantity++),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Cash"),
                selected: paymentMode == "Cash",
                onSelected: (s) => setState(() => paymentMode = "Cash"),
              ),
              const SizedBox(width: 15),
              ChoiceChip(
                label: const Text("M-Pesa"),
                selected: paymentMode == "M-Pesa",
                onSelected: (s) => setState(() => paymentMode = "M-Pesa"),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: cart.isEmpty ? null : _checkout,
              child: Text(
                "COMPLETE SALE (KES ${total.toInt()})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _quickSelectBar(),
        ],
      ),
    );
  }

  Widget _quickSelectBar() {
    if (filteredProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredProducts.length,
        itemBuilder: (c, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(
            label: Text(filteredProducts[i].name),
            onPressed: () => setState(() {
              final idx = cart.indexWhere((it) => it.product.id == filteredProducts[i].id);
              if (idx != -1) {
                cart[idx].quantity++;
              } else {
                cart.add(SaleItem(product: filteredProducts[i]));
              }
            }),
          ),
        ),
      ),
    );
  }
}

// --- BARCODE SCANNER SCREEN ---
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first.rawValue;
            if (barcode != null) {
              Navigator.pop(context, barcode);
            }
          }
        },
      ),
    );
  }
}

// --- 3. PRODUCTS SCREEN ---
class ProductsScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const ProductsScreen({super.key, required this.onRefresh});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final pStr = prefs.getString('products') ?? '[]';
    setState(() {
      products = (jsonDecode(pStr) as List).map((p) => Product.fromJson(p)).toList();
    });
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList()));
    widget.onRefresh();
  }

  void _addProduct() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final sellingController = TextEditingController();
    final stockController = TextEditingController();
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: "Buying Price (KES)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sellingController,
                decoration: const InputDecoration(labelText: "Selling Price (KES)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: "Initial Stock"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: "Barcode (Optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  costController.text.isEmpty ||
                  sellingController.text.isEmpty ||
                  stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final cost = int.tryParse(costController.text);
              final selling = int.tryParse(sellingController.text);
              final stock = int.tryParse(stockController.text);

              if (cost == null || selling == null || stock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid numbers')),
                );
                return;
              }

              if (selling <= cost) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Selling price must be higher than buying price')),
                );
                return;
              }

              products.add(Product(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                costPrice: cost,
                sellingPrice: selling,
                stock: stock,
                barcode: barcodeController.text.trim(),
              ));

              _saveProducts();
              setState(() {});
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${products[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => products.removeAt(index));
              _saveProducts();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _updateStock(int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock for ${products[index].name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${products[index].stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Add Stock',
                hintText: 'Enter quantity to add',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                setState(() {
                  products[index].stock += quantity;
                });
                _saveProducts();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock updated!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Inventory")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products yet', style: TextStyle(fontSize: 18)),
            Text('Tap + to add your first product'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (c, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: products[i].stock < 5 ? Colors.red.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: products[i].stock < 5 ? Colors.red : Colors.green,
              child: Text(
                '${products[i].stock}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              products[i].name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: products[i].stock < 5 ? Colors.red : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selling: KES ${products[i].sellingPrice}'),
                Text(
                  'Profit: KES ${products[i].sellingPrice - products[i].costPrice}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'stock',
                  child: Row(
                    children: [
                      Icon(Icons.add_box),
                      SizedBox(width: 8),
                      Text('Add Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'stock') {
                  _updateStock(i);
                } else if (value == 'delete') {
                  _deleteProduct(i);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

// --- 4. EXPENSE SCREEN WITH DELETE ---
class ExpenseScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const ExpenseScreen({super.key, required this.onRefresh});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final eStr = prefs.getString('expenses_$today') ?? '[]';
    setState(() {
      expenses = (jsonDecode(eStr) as List).map((e) => Expense.fromJson(e)).toList();
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('expenses_$today', jsonEncode(expenses.map((e) => e.toJson()).toList()));
    widget.onRefresh();
  }

  void _addExpense() {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount (KES)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isEmpty || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid amount')),
                );
                return;
              }

              expenses.add(Expense(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                description: descController.text.trim(),
                amount: amount,
                date: DateTime.now(),
              ));

              _saveExpenses();
              setState(() {});
              Navigator.pop(c);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense added!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expenses[index].description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => expenses.removeAt(index));
              _saveExpenses();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Expenses"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Total: KES $total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
      body: expenses.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No expenses today', style: TextStyle(fontSize: 18)),
            Text('Tap + to add an expense'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (c, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.money_off, color: Colors.white),
            ),
            title: Text(expenses[i].description),
            subtitle: Text(
              DateFormat('MMM dd, yyyy - h:mm a').format(expenses[i].date),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "KES ${expenses[i].amount}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteExpense(i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 5. DEBT SCREEN ---
class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  List<Debt> debts = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final dStr = prefs.getString('debts') ?? '[]';
    setState(() {
      debts = (jsonDecode(dStr) as List).map((d) => Debt.fromJson(d)).toList();
    });
  }

  Future<void> _saveDebts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('debts', jsonEncode(debts.map((d) => d.toJson()).toList()));
  }

  void _addDebt() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("New Customer Debt"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Customer Name"),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone (254712345678)"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount (KES)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid amount')),
                );
                return;
              }

              debts.add(Debt(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                customerName: nameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                totalAmount: amount,
                date: DateTime.now(),
              ));

              _saveDebts();
              setState(() {});
              Navigator.pop(c);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debt record added!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _sendReminder(Debt debt) async {
    final msg =
        "Hello ${debt.customerName}, Kim's Duka reminder: you have a balance of KES ${debt.remaining.toInt()}.";
    final url = Uri.parse("whatsapp://send?phone=${debt.phoneNumber}&text=$msg");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not installed')),
        );
      }
    }
  }

  void _recordPayment(int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment from ${debts[index].customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: KES ${debts[index].totalAmount.toInt()}'),
            Text('Paid: KES ${debts[index].paidAmount.toInt()}'),
            Text(
              'Balance: KES ${debts[index].remaining.toInt()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                hintText: 'Enter amount received',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final payment = double.tryParse(controller.text);
              if (payment != null && payment > 0) {
                setState(() {
                  debts[index].paidAmount += payment;
                  if (debts[index].remaining <= 0) {
                    debts.removeAt(index);
                  }
                });
                _saveDebts();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded!')),
                );
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = debts.fold(0.0, (sum, d) => sum + d.remaining);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deni Records"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Total: KES ${totalDebt.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: const Icon(Icons.person_add),
      ),
      body: debts.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No debt records', style: TextStyle(fontSize: 18)),
            Text('Tap + to add a customer debt'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: debts.length,
        itemBuilder: (c, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                debts[i].customerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              debts[i].customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Balance: KES ${debts[i].remaining.toInt()}\n'
                  'Date: ${DateFormat('MMM dd, yyyy').format(debts[i].date)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.payment, color: Colors.blue),
                  onPressed: () => _recordPayment(i),
                  tooltip: 'Record Payment',
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.green),
                  onPressed: () => _sendReminder(debts[i]),
                  tooltip: 'Send Reminder',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}