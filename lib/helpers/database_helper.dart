import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gallery.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const blobType = 'BLOB';
    const boolType = 'INTEGER'; // For boolean values (0 or 1)

    await db.execute(''' 
      CREATE TABLE images (
        id $idType, 
        image $blobType, 
        date $textType, 
        is_favorite $boolType DEFAULT 0
      )
    ''');
  }

  // This method handles upgrades if the database schema changes
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ensure the is_favorite column exists
      await db.execute('''
        ALTER TABLE images ADD COLUMN is_favorite INTEGER DEFAULT 0
      ''');
    }
  }

  Future<int> insertImage(File imageFile, DateTime date) async {
    final db = await instance.database;
    final imageBytes = await imageFile.readAsBytes();
    final dateString = date.toIso8601String();

    return await db.insert('images', {
      'image': imageBytes,
      'date': dateString,
    });
  }

  Future<int> deleteImage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'images',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFavoriteStatus(int id, bool isFavorite) async {
    final db = await instance.database;
    await db.update(
      'images',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllImages() async {
    final db = await instance.database;
    return await db.query('images');
  }

  Future<List<Map<String, dynamic>>> getFavoriteImages() async {
    final db = await instance.database;
    return await db.query(
      'images',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
  }
}
