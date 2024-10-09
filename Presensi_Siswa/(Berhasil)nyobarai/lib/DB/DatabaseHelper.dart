import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Nama database dan versi
  static final _databaseName = "faces_database.db";
  static final _databaseVersion = 3; // Update versi database

  // Nama tabel dan kolom
  static final table = 'registered_faces';
  static final columnId = '_id';
  static final columnName = 'name';
  static final columnNIS = 'nis'; 
  static final columnKelas = 'kelas'; 
  static final columnNoHpOrtu = 'noHpOrtu'; // Tambahkan kolom No HP Orang Tua
  static final columnEmbedding = 'embedding';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // Getter database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inisialisasi database
  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Tambahkan metode upgrade
      version: _databaseVersion,
    );
  }

  // Membuat tabel baru dengan kolom tambahan
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnNIS TEXT, 
        $columnKelas TEXT, 
        $columnNoHpOrtu TEXT, -- Kolom No HP Orang Tua
        $columnEmbedding TEXT NOT NULL
      )
    ''');
  }

  // Menangani upgrade database jika versi meningkat
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE $table ADD COLUMN $columnNoHpOrtu TEXT;
      ''');
    }
  }

  // Menambahkan data baru
  Future<int> insert(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  // Mengambil semua baris
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await database;
    return await db.query(table);
  }

  // Mengambil baris berdasarkan ID
  Future<Map<String, dynamic>?> queryRow(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: [columnId, columnName, columnNIS, columnKelas, columnNoHpOrtu, columnEmbedding],
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Memperbarui data berdasarkan ID
  Future<int> update(Map<String, dynamic> row) async {
    final db = await database;
    int id = row[columnId];
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Menghapus data berdasarkan ID
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Mengecek apakah NIS sudah ada
  Future<bool> isNisExists(String nis) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: '$columnNIS = ?',
      whereArgs: [nis],
    );
    return maps.isNotEmpty;
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(table, where: '1=1');
  }
}
