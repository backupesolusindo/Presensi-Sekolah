import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "FaceRecognitionDB.db";
  static const _databaseVersion = 1;

  static const table = 'registered_faces';

  static const columnId = '_id';
  static const columnName = 'name';
  static const columnEmbedding = 'embedding';

  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open/create the database at a given path
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create the database table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnEmbedding TEXT NOT NULL
      )
    ''');
  }

  // Insert a face into the database
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Query all rows in the table
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // Query a specific row by ID
  Future<Map<String, dynamic>?> queryRow(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(table,
        columns: [columnId, columnName, columnEmbedding],
        where: '$columnId = ?',
        whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // Update a row in the database
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete a row in the database
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete all rows in the database
  Future<int> deleteAll() async {
    Database db = await instance.database;
    return await db.delete(table);
  }

  init() {}
}
