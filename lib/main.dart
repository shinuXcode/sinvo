import 'package:flutter/material.dart';
import 'sadab_core/billing.dart';
import 'sadab_core/models.dart';
import 'sadab_core/stock.dart';

void main() => runApp(const SadabInvoApp());

class SadabInvoApp extends StatelessWidget {
  const SadabInvoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sadab Invo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
    home: const InvoHome(),
  );
}

class InvoHome extends StatefulWidget {
  const InvoHome({super.key});
  @override State<InvoHome> createState() => _InvoHomeState();
}

class _InvoHomeState extends State<InvoHome> {
  final cart = Cart();
  final products = <Product>[
    const Product(id: 'p1', name: 'Demo Product', sku: 'DEMO-001', category: 'General', buyPrice: 50, sellPrice: 80, stock: 20),
  ];

  @override void dispose() { cart.dispose(); super.dispose(); }

  void add(Product p) {
    try { cart.add(p); setState(() {}); }
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  void checkout() {
    try {
      final r = BillingService.checkout(cart: cart, inventory: products, saleId: DateTime.now().millisecondsSinceEpoch.toString());
      setState(() { products..clear()..addAll(r.inventory); cart.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale saved: ₹' + r.sale.total.toStringAsFixed(2))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = products.fold<int>(0, (s, p) => s + p.stock);
    final value = StockService.inventoryValue(products);
    return Scaffold(
      appBar: AppBar(title: const Text('Sadab Invo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _Stat('Products', products.length.toString())),
            Expanded(child: _Stat('Stock', stock.toString())),
            Expanded(child: _Stat('Value', '₹' + value.toStringAsFixed(0))),
          ]),
          const SizedBox(height: 16),
          Text('Products', style: Theme.of(context).textTheme.headlineSmall),
          ...products.map((p) => Card(child: ListTile(
            title: Text(p.name),
            subtitle: Text(p.sku + ' • Stock: ' + p.stock.toString() + ' • ₹' + p.sellPrice.toStringAsFixed(2)),
            trailing: FilledButton(onPressed: p.stock > 0 ? () => add(p) : null, child: const Text('Add')),
          ))),
          const SizedBox(height: 16),
          Text('Billing', style: Theme.of(context).textTheme.headlineSmall),
          Card(child: Column(children: [
            if (cart.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Cart is empty'))
            else ...cart.lines.map((l) => ListTile(
              title: Text(l.product.name),
              subtitle: Text('Qty: ' + l.qty.toString()),
              trailing: Text('₹' + l.lineTotal.toStringAsFixed(2)),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Text('Total: ₹' + cart.total.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge)),
                FilledButton.icon(onPressed: cart.isEmpty ? null : checkout, icon: const Icon(Icons.receipt_long), label: const Text('Checkout')),
              ]),
            ),
          ])),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label)]),
  ));
}
