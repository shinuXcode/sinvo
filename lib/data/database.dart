import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  late Database db;
  final uuid = const Uuid();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    db = await openDatabase(
      p.join(dir.path, 'sinvo.db'),
      version: 1,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE products(id TEXT PRIMARY KEY,name TEXT NOT NULL,sku TEXT NOT NULL UNIQUE,barcode TEXT UNIQUE,purchase_price REAL NOT NULL DEFAULT 0,selling_price REAL NOT NULL DEFAULT 0,stock REAL NOT NULL DEFAULT 0,min_stock REAL NOT NULL DEFAULT 0,unit TEXT NOT NULL DEFAULT "pcs",active INTEGER NOT NULL DEFAULT 1,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE customers(id TEXT PRIMARY KEY,name TEXT NOT NULL,phone TEXT,address TEXT,notes TEXT,due REAL NOT NULL DEFAULT 0,created_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE sales(id TEXT PRIMARY KEY,invoice_no TEXT NOT NULL UNIQUE,total REAL NOT NULL,paid REAL NOT NULL,due REAL NOT NULL,payment_method TEXT NOT NULL,created_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE sale_items(id TEXT PRIMARY KEY,sale_id TEXT NOT NULL,product_id TEXT NOT NULL,quantity REAL NOT NULL,rate REAL NOT NULL,total REAL NOT NULL,FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE)');
        await d.execute('CREATE TABLE expenses(id TEXT PRIMARY KEY,amount REAL NOT NULL,category TEXT NOT NULL,description TEXT,payment_method TEXT NOT NULL,created_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE stock_transactions(id TEXT PRIMARY KEY,product_id TEXT NOT NULL,type TEXT NOT NULL,quantity REAL NOT NULL,before_stock REAL NOT NULL,after_stock REAL NOT NULL,reference_id TEXT,created_at TEXT NOT NULL)');
        await d.execute('CREATE TABLE app_settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
        await d.execute('CREATE INDEX idx_products_name ON products(name)');
        await d.execute('CREATE INDEX idx_products_sku ON products(sku)');
        await d.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
        await d.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
        await d.insert('app_settings', {'key':'invoice_prefix','value':'INV'});
        await d.insert('app_settings', {'key':'invoice_number','value':'1001'});
        await d.insert('app_settings', {'key':'negative_stock','value':'0'});
      },
      onOpen: (d) async => d.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<List<Map<String,Object?>>> products({String q = '', bool low = false}) async {
    final args=<Object?>[];
    var where='active=1';
    if(q.trim().isNotEmpty) {
      where += ' AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)';
      final x='%'+q.trim()+'%';
      args.addAll([x,x,x]);
    }
    if(low) where += ' AND stock<=min_stock';
    return db.rawQuery('SELECT * FROM products WHERE '+where+' ORDER BY name LIMIT 100',args);
  }

  Future<Map<String,Object?>> dashboard() async {
    final day=DateTime.now().toIso8601String().substring(0,10);
    final s=await db.rawQuery('SELECT COALESCE(SUM(total),0) sales,COUNT(*) bills FROM sales WHERE substr(created_at,1,10)=?', [day]);
    final e=await db.rawQuery('SELECT COALESCE(SUM(amount),0) expenses FROM expenses WHERE substr(created_at,1,10)=?', [day]);
    final l=await db.rawQuery('SELECT COUNT(*) low FROM products WHERE active=1 AND stock<=min_stock');
    final c=await db.rawQuery('SELECT COALESCE(SUM(due),0) due FROM customers');
    return {'sales':s.first['sales'],'bills':s.first['bills'],'expenses':e.first['expenses'],'low':l.first['low'],'due':c.first['due']};
  }

  Future<void> saveProduct(Map<String,Object?> data,{String? id}) async {
    final now=DateTime.now().toIso8601String();
    if(id==null) {
      await db.insert('products',{...data,'id':uuid.v4(),'created_at':now,'updated_at':now});
    } else {
      await db.update('products',{...data,'updated_at':now},where:'id=?',whereArgs:[id]);
    }
  }

  Future<void> saveCustomer(Map<String,Object?> data) async {
    await db.insert('customers',{...data,'id':uuid.v4(),'created_at':DateTime.now().toIso8601String()});
  }

  Future<List<Map<String,Object?>>> customers(String q) async {
    if(q.isEmpty) return db.query('customers',orderBy:'name');
    return db.query('customers',where:'name LIKE ? OR phone LIKE ?',whereArgs:['%'+q+'%','%'+q+'%'],orderBy:'name');
  }

  Future<void> addExpense(double amount,String category,String description) async {
    await db.insert('expenses',{'id':uuid.v4(),'amount':amount,'category':category,'description':description,'payment_method':'Cash','created_at':DateTime.now().toIso8601String()});
  }

  Future<void> completeSale(List<Map<String,Object?>> items) async {
    await db.transaction((tx) async {
      for(final item in items) {
        final product=(await tx.query('products',where:'id=? AND active=1',whereArgs:[item['productId']])).first;
        final qty=item['qty'] as double;
        final stock=(product['stock'] as num).toDouble();
        if(qty>stock && (await tx.query('app_settings',where:'key=?',whereArgs:['negative_stock'])).first['value']=='0') {
          throw StateError('Insufficient stock for '+product['name'].toString());
        }
      }
      final total=items.fold<double>(0,(sum,item)=>sum+(item['total'] as double));
      final paid=total;
      final now=DateTime.now().toIso8601String();
      final saleId=uuid.v4();
      final n=int.tryParse((await tx.query('app_settings',where:'key=?',whereArgs:['invoice_number'])).first['value'].toString())??1001;
      final prefix=(await tx.query('app_settings',where:'key=?',whereArgs:['invoice_prefix'])).first['value'].toString();
      await tx.update('app_settings',{'value':(n+1).toString()},where:'key=?',whereArgs:['invoice_number']);
      final invoice=prefix+'-'+n.toString();
      await tx.insert('sales',{'id':saleId,'invoice_no':invoice,'total':total,'paid':paid,'due':0,'payment_method':'Cash','created_at':now});
      for(final item in items) {
        final product=(await tx.query('products',where:'id=?',whereArgs:[item['productId']])).first;
        final before=(product['stock'] as num).toDouble();
        final qty=item['qty'] as double;
        final after=before-qty;
        await tx.insert('sale_items',{'id':uuid.v4(),'sale_id':saleId,'product_id':item['productId'],'quantity':qty,'rate':item['rate'],'total':item['total']});
        await tx.update('products',{'stock':after,'updated_at':now},where:'id=?',whereArgs:[item['productId']]);
        await tx.insert('stock_transactions',{'id':uuid.v4(),'product_id':item['productId'],'type':'Sale','quantity':-qty,'before_stock':before,'after_stock':after,'reference_id':saleId,'created_at':now});
      }
    });
  }
}
