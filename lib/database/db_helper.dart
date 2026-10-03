import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habitos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE habits (
  id $idType,
  title $textType,
  description $textType,
  iconCodePoint $integerType DEFAULT 57923,
  colorValue $integerType DEFAULT 4278224520,
  frequencyType $textType DEFAULT 'daily',
  frequencyDays $textType DEFAULT '[1,2,3,4,5,6,7]',
  targetTimesPerWeek $integerType DEFAULT 7,
  alarmTimes $textType DEFAULT '[]',
  createdAt $textType DEFAULT '',
  isArchived $boolType DEFAULT 0,
  alarmTime $textNullable
)
''');

    await db.execute('''
CREATE TABLE habit_records (
  id $idType,
  habitId $integerType,
  date $textType,
  isCompleted $boolType,
  notes $textNullable,
  FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE habits ADD COLUMN iconCodePoint INTEGER DEFAULT 57923");
      await db.execute("ALTER TABLE habits ADD COLUMN colorValue INTEGER DEFAULT 4278224520");
      await db.execute("ALTER TABLE habits ADD COLUMN frequencyType TEXT DEFAULT 'daily'");
      await db.execute("ALTER TABLE habits ADD COLUMN frequencyDays TEXT DEFAULT '[1,2,3,4,5,6,7]'");
      await db.execute("ALTER TABLE habits ADD COLUMN targetTimesPerWeek INTEGER DEFAULT 7");
      await db.execute("ALTER TABLE habits ADD COLUMN alarmTimes TEXT DEFAULT '[]'");
      await db.execute("ALTER TABLE habits ADD COLUMN createdAt TEXT DEFAULT ''");
      await db.execute("ALTER TABLE habits ADD COLUMN isArchived INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE habit_records ADD COLUMN notes TEXT");
    }
  }

  // Habit Operations
  Future<Habit> insertHabit(Habit habit) async {
    final db = await instance.database;
    final id = await db.insert('habits', habit.toMap());
    return habit.copyWith(id: id);
  }

  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await instance.database;
    final whereClause = includeArchived ? null : 'isArchived = 0';
    final result = await db.query('habits', where: whereClause, orderBy: 'id DESC');
    return result.map((json) => Habit.fromMap(json)).toList();
  }

  Future<Habit?> getHabitById(int id) async {
    final db = await instance.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    return db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> archiveHabit(int id, bool archive) async {
    final db = await instance.database;
    return db.update(
      'habits',
      {'isArchived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await instance.database;
    await db.delete('habit_records', where: 'habitId = ?', whereArgs: [id]);
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Habit Record Operations
  Future<HabitRecord?> getHabitRecord(int habitId, String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'habit_records',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    if (maps.isNotEmpty) {
      return HabitRecord.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> insertOrUpdateHabitRecord(HabitRecord record) async {
    final db = await instance.database;
    final existing = await getHabitRecord(record.habitId, record.date);
    if (existing != null) {
      return db.update(
        'habit_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      return db.insert('habit_records', record.toMap());
    }
  }

  Future<List<HabitRecord>> getHabitRecordsForDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'habit_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((json) => HabitRecord.fromMap(json)).toList();
  }

  Future<List<HabitRecord>> getAllHabitRecords() async {
    final db = await instance.database;
    final result = await db.query('habit_records');
    return result.map((json) => HabitRecord.fromMap(json)).toList();
  }

  Future<List<HabitRecord>> getHabitRecordsForHabit(int habitId) async {
    final db = await instance.database;
    final result = await db.query(
      'habit_records',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date ASC',
    );
    return result.map((json) => HabitRecord.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
