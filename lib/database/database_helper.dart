
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/todo.dart';
import '../models/calendar_event.dart';
import 'database_schema.dart';

class DatabaseHelper {
  // Eine gemeinsame Instanz für die App
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Privater Konstruktor
  DatabaseHelper._init();

  Database? _database;

  // Datenbank laden oder erstmalig erstellen
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }
  
  
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'todo_database.db');

    return openDatabase(
      path,
      version: 5,

      onCreate: (db, version) async {
        await db.execute(DatabaseSchema.createTodosTable);
        await db.execute(DatabaseSchema.createEventsTable);
        await db.execute(DatabaseSchema.createEventExceptionsTable);

        await _createFinanceTables(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(DatabaseSchema.createEventsTable);
        }

        if (oldVersion < 3) {
          await _createFinanceTables(db);
        }
        
        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE todos
            ADD COLUMN priority INTEGER NOT NULL DEFAULT 2
          ''');
        }
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE events ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none'");
          await db.execute('ALTER TABLE events ADD COLUMN recurrence_until TEXT');
          await db.execute(DatabaseSchema.createEventExceptionsTable);
        }
      },
    );
  }

  Future<void> _createFinanceTables(Database db) async {
    await db.execute(DatabaseSchema.createFinanceMonthsTable);
    await db.execute(DatabaseSchema.createFinanceFixedCostsTable);
    await db.execute(DatabaseSchema.createFinancePurchasesTable);
    await db.execute(DatabaseSchema.createFinanceMonthlyCostsTable);
  }

  // CREATE: Neues To-do speichern
  Future<int> insertTodo(Todo todo) async {
    final db = await database;

    return await db.insert(
      'todos',
      todo.toMap()..remove('id'),
    );
  }

  // READ: Alle To-dos laden
  Future<List<Todo>> getTodos() async {
    final db = await database;

    final result = await db.query(
      'todos',
      orderBy: 'id DESC',
    );

    return result.map((map) => Todo.fromMap(map)).toList();
  }

  // UPDATE: Bestehendes To-do aktualisieren
  Future<int> updateTodo(Todo todo) async {
    if (todo.id == null) {
      throw ArgumentError('Todo benötigt eine ID zum Aktualisieren.');
    }

    final db = await database;

    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // DELETE: To-do löschen
  Future<int> deleteTodo(int id) async {
    final db = await database;

    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Verbindung bei Bedarf schließen
  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Neuen Einzeltermin oder Serienbeginn speichern
  Future<int> insertEvent(CalendarEvent event) async {
    final db = await database;
    return db.insert('events', event.toMap()..remove('id'));
  }

  Future<CalendarEvent?> getSeriesEvent(int id) async {
    final db = await database;
    final rows = await db.query('events', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : CalendarEvent.fromMap(rows.first);
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime date) =>
      getEventsForRange(date, date);

  // Alle tatsächlichen Vorkommen innerhalb eines begrenzten Zeitraums.
  // Auch auf einen anderen Tag verschobene Ausnahmen werden berücksichtigt.
  Future<List<CalendarEvent>> getEventsForRange(DateTime from, DateTime to) async {
    final start = CalendarEvent.onlyDate(from);
    final end = CalendarEvent.onlyDate(to);
    if (end.isBefore(start)) return [];
    if (end.difference(start).inDays > 370) {
      throw ArgumentError('Kalenderzeitraum darf maximal 371 Tage umfassen.');
    }
    final db = await database;
    // Auch Serien laden, deren Ausnahmen in diesen Zeitraum verschoben wurden.
    final seriesRows = await db.query('events');
    final series = seriesRows.map(CalendarEvent.fromMap).toList();
    final seriesIds = series.map((e) => e.id!).toSet();
    if (seriesIds.isEmpty) return [];

    final exceptionRows = await db.query('event_exceptions');
    final exceptionByKey = <String, Map<String, Object?>>{};
    for (final row in exceptionRows) {
      final id = row['event_id'] as int;
      if (seriesIds.contains(id)) {
        exceptionByKey['$id:${row['occurrence_date']}'] = row;
      }
    }

    final result = <CalendarEvent>[];
    for (final original in series) {
      var date = start;
      while (!date.isAfter(end)) {
        if (original.occursOn(date)) {
          final key = '${original.id}:${CalendarEvent.dateKey(date)}';
          final exception = exceptionByKey[key];
          if (exception == null) {
            result.add(original.at(date,
              originalDate: original.recurrence == 'none' ? null : date));
          } else if (exception['is_cancelled'] != 1) {
            final moved = DateTime.parse(exception['override_date'] as String);
            if (CalendarEvent.onlyDate(moved) == date) {
              result.add(_fromException(original, exception));
            }
          }
        }
        date = date.add(const Duration(days: 1));
      }
      // Verschobene Ausnahmen, deren Originaldatum außerhalb des Fensters liegt
      for (final row in exceptionByKey.values) {
        if (row['event_id'] != original.id || row['is_cancelled'] == 1) continue;
        final movedText = row['override_date'] as String?;
        if (movedText == null) continue;
        final moved = DateTime.parse(movedText);
        if (moved.isBefore(start) || moved.isAfter(end)) continue;
        final initial = DateTime.parse(row['occurrence_date'] as String);
        if (!original.occursOn(initial)) continue;
        if (initial.isBefore(start) || initial.isAfter(end)) {
          result.add(_fromException(original, row));
        } else if (CalendarEvent.onlyDate(moved) != initial) {
          result.add(_fromException(original, row));
        }
      }
    }
    // Doppelte Ausnahmen ausschließen, insbesondere an verschobenen Tagen
    final unique = <String, CalendarEvent>{};
    for (final e in result) {
      unique['${e.id}:${CalendarEvent.dateKey(e.occurrenceDate ?? e.date)}'] = e;
    }
    final sorted = unique.values.toList();
    sorted.sort((a, b) {
      final day = a.date.compareTo(b.date);
      if (day != 0) return day;
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      final time = (a.startMinute ?? 0).compareTo(b.startMinute ?? 0);
      return time != 0 ? time : (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return sorted;
  }

  CalendarEvent _fromException(CalendarEvent original, Map<String, Object?> row) {
    return CalendarEvent(
      id: original.id,
      title: row['title'] as String? ?? original.title,
      description: row['description'] as String? ?? original.description,
      location: row['location'] as String? ?? original.location,
      date: DateTime.parse(row['override_date'] as String),
      startMinute: row['start_minute'] as int?,
      endMinute: row['end_minute'] as int?,
      isAllDay: row['is_all_day'] == 1,
      recurrence: original.recurrence,
      recurrenceUntil: original.recurrenceUntil,
      occurrenceDate: DateTime.parse(row['occurrence_date'] as String),
    );
  }

  // Nur für ältere Aufrufe: 12 Monate rund um heute, begrenzter Zeitraum.
  Future<List<CalendarEvent>> getAllEvents() async {
    final today = DateTime.now();
    return getEventsForRange(DateTime(today.year, today.month - 6, 1),
        DateTime(today.year, today.month + 6, 0));
  }

  Future<int> updateEvent(CalendarEvent event) async {
    if (event.id == null) throw ArgumentError('Termin benötigt eine ID.');
    final db = await database;
    return db.transaction((txn) async {
      final previous = await txn.query('events', where: 'id = ?', whereArgs: [event.id], limit: 1);
      if (previous.isEmpty) return 0;
      final before = CalendarEvent.fromMap(previous.first);
      // Änderung der Wiederholung macht bisherige Einzelausnahmen ungültig.
      if (before.recurrence != event.recurrence ||
          CalendarEvent.dateKey(before.date) != CalendarEvent.dateKey(event.date) ||
          (before.recurrenceUntil == null ? null : CalendarEvent.dateKey(before.recurrenceUntil!)) !=
          (event.recurrenceUntil == null ? null : CalendarEvent.dateKey(event.recurrenceUntil!))) {
        await txn.delete('event_exceptions', where: 'event_id = ?', whereArgs: [event.id]);
      }
      return txn.update('events', event.toMap()..remove('id'), where: 'id = ?', whereArgs: [event.id]);
    });
  }

  Future<void> updateEventOccurrence(CalendarEvent occurrence, CalendarEvent changed) async {
    final id = occurrence.id;
    if (id == null || occurrence.occurrenceDate == null) {
      throw ArgumentError('Ungültige Serienwiederholung.');
    }
    final db = await database;
    await db.insert('event_exceptions', {
      'event_id': id,
      'occurrence_date': CalendarEvent.dateKey(occurrence.occurrenceDate!),
      'is_cancelled': 0,
      'override_date': CalendarEvent.dateKey(changed.date),
      'title': changed.title,
      'description': changed.description,
      'location': changed.location,
      'start_minute': changed.isAllDay ? null : changed.startMinute,
      'end_minute': changed.isAllDay ? null : changed.endMinute,
      'is_all_day': changed.isAllDay ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEventOccurrence(CalendarEvent occurrence) async {
    final id = occurrence.id;
    if (id == null || occurrence.occurrenceDate == null) {
      throw ArgumentError('Ungültige Serienwiederholung.');
    }
    final db = await database;
    await db.insert('event_exceptions', {
      'event_id': id,
      'occurrence_date': CalendarEvent.dateKey(occurrence.occurrenceDate!),
      'is_cancelled': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('event_exceptions', where: 'event_id = ?', whereArgs: [id]);
      return txn.delete('events', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Monatskennung, z. B. 2026-10
  String financeMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Monat anlegen, falls er noch nicht existiert.
  // Erbt das Budget des letzten gespeicherten Monats.
  Future<void> ensureFinanceMonth(DateTime date) async {
    final db = await database;
    final key = financeMonthKey(date);

    await db.transaction((txn) async {
      final existing = await txn.query(
        'finance_months',
        where: 'month_key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (existing.isNotEmpty) return;

      final previous = await txn.query(
        'finance_months',
        columns: ['budget_cents'],
        where: 'month_key < ?',
        whereArgs: [key],
        orderBy: 'month_key DESC',
        limit: 1,
      );

      final budget = previous.isEmpty
          ? 0
          : previous.first['budget_cents'] as int;

      final fixedCosts = await txn.query('finance_fixed_costs');

      int fixedSum = 0;

      for (final cost in fixedCosts) {
        fixedSum += cost['amount_cents'] as int;
      }

      await txn.insert('finance_months', {
        'month_key': key,
        'budget_cents': budget,
        'fixed_cents': fixedSum,
      });

      for (final cost in fixedCosts) {
        await txn.insert('finance_monthly_costs', {
          'month_key': key,
          'title': cost['title'],
          'amount_cents': cost['amount_cents'],
        });
      }
    });
  }

  // Monatsbudget ändern
  Future<void> setFinanceBudget(
    DateTime date,
    int cents,
  ) async {
    await ensureFinanceMonth(date);

    final db = await database;

    await db.update(
      'finance_months',
      {'budget_cents': cents},
      where: 'month_key = ?',
      whereArgs: [financeMonthKey(date)],
    );
  }

  // Fixkosten für den aktuellen Monat neu berechnen.
  // Vergangene Monate bleiben unverändert.
  Future<void> syncCurrentFixedCosts() async {
    final db = await database;
    final now = DateTime.now();
    final key = financeMonthKey(now);

    await ensureFinanceMonth(now);

    await db.transaction((txn) async {
      final costs = await txn.query('finance_fixed_costs');

      int sum = 0;
      for (final cost in costs) {
        sum += cost['amount_cents'] as int;
      }

      await txn.delete(
        'finance_monthly_costs',
        where: 'month_key = ?',
        whereArgs: [key],
      );

      for (final cost in costs) {
        await txn.insert('finance_monthly_costs', {
          'month_key': key,
          'title': cost['title'],
          'amount_cents': cost['amount_cents'],
        });
      }

      await txn.update(
        'finance_months',
        {'fixed_cents': sum},
        where: 'month_key = ?',
        whereArgs: [key],
      );
    });
  }

  // Wiederkehrende Fixkosten hinzufügen
  Future<void> addFixedCost(String title, int cents) async {
    final db = await database;

    await db.insert('finance_fixed_costs', {
      'title': title,
      'amount_cents': cents,
    });

    await syncCurrentFixedCosts();
  }

  // Fixkosten anhand ihrer ID ändern; dieselbe ID bleibt erhalten.
  // Anschließend den aktuellen Monat neu berechnen.
  Future<void> updateFixedCost(int id, String title, int cents) async {
    final cleanedTitle = title.trim();
    if (cleanedTitle.isEmpty || cents <= 0) {
      throw ArgumentError('Titel und positiver Betrag erforderlich.');
    }

    final db = await database;
    final affected = await db.update(
      'finance_fixed_costs',
      {'title': cleanedTitle, 'amount_cents': cents},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (affected == 0) {
      throw StateError('Die Fixkosten mit ID $id existieren nicht.');
    }
    await syncCurrentFixedCosts();
  }

  // Wiederkehrende Fixkosten löschen
  Future<void> deleteFixedCost(int id) async {
    final db = await database;

    await db.delete(
      'finance_fixed_costs',
      where: 'id = ?',
      whereArgs: [id],
    );

    await syncCurrentFixedCosts();
  }

  // Kauf erfassen
  Future<void> addFinancePurchase({
    required String title,
    required int amountCents,
    required String category,
    required DateTime date,
  }) async {
    await ensureFinanceMonth(date);

    final db = await database;

    final dateText =
        '${financeMonthKey(date)}-${date.day.toString().padLeft(2, '0')}';

    await db.insert('finance_purchases', {
      'title': title,
      'amount_cents': amountCents,
      'category': category,
      'purchase_date': dateText,
    });
  }

  // Kauf löschen
  Future<void> deleteFinancePurchase(int id) async {
    final db = await database;

    await db.delete(
      'finance_purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Daten für die aktuelle Übersicht
  Future<Map<String, Object?>> getFinanceOverview(
    DateTime date,
  ) async {
    await ensureFinanceMonth(date);

    final db = await database;
    final key = financeMonthKey(date);

    final months = await db.query(
      'finance_months',
      where: 'month_key = ?',
      whereArgs: [key],
      limit: 1,
    );

    final purchases = await db.query(
      'finance_purchases',
      where: 'purchase_date LIKE ?',
      whereArgs: ['$key-%'],
      orderBy: 'purchase_date DESC, id DESC',
    );

    final fixedCosts = await db.query(
      'finance_monthly_costs',
      where: 'month_key = ?',
      whereArgs: [key],
      orderBy: 'id ASC',
    );

    int spent = 0;

    for (final purchase in purchases) {
      spent += purchase['amount_cents'] as int;
    }

    final month = months.first;

    final budget = month['budget_cents'] as int;
    final fixed = month['fixed_cents'] as int;

    return {
      'budget': budget,
      'fixed': fixed,
      'spent': spent,
      'remaining': budget - fixed - spent,
      'purchases': purchases,
      'fixedCosts': fixedCosts,
    };
  }

  // Aktuell eingestellte Fixkosten
  Future<List<Map<String, Object?>>> getActiveFixedCosts() async {
    final db = await database;

    return db.query(
      'finance_fixed_costs',
      orderBy: 'id ASC',
    );
  }

  // Archivübersicht aller abgeschlossenen Monate
  Future<List<Map<String, Object?>>> getFinanceArchive() async {
    final db = await database;
    final currentKey = financeMonthKey(DateTime.now());

    return db.rawQuery('''
      SELECT
        m.month_key,
        m.budget_cents,
        m.fixed_cents,
        COALESCE(SUM(p.amount_cents), 0) AS spent_cents
      FROM finance_months m
      LEFT JOIN finance_purchases p
        ON substr(p.purchase_date, 1, 7) = m.month_key
      WHERE m.month_key < ?
      GROUP BY m.month_key, m.budget_cents, m.fixed_cents
      ORDER BY m.month_key DESC
    ''', [currentKey]);
  }

  // Test später löschen
  Future<void> insertFinanceArchiveTestData() async {
    final db = await database;

    const testMonth = '2026-09';

    await db.transaction((txn) async {
      // Verhindern, dass bestehende Daten überschrieben werden.
      final existingMonth = await txn.query(
        'finance_months',
        where: 'month_key = ?',
        whereArgs: [testMonth],
        limit: 1,
      );

      if (existingMonth.isNotEmpty) {
        throw StateError(
          'Für September 2026 existieren bereits Finanzdaten. '
          'Der Test wurde nicht eingefügt.',
        );
      }

      // Monatsübersicht
      await txn.insert('finance_months', {
        'month_key': testMonth,
        'budget_cents': 150000,
        'fixed_cents': 60000,
      });

      // Historische Fixkosten, nicht die aktiven Fixkosten
      await txn.insert('finance_monthly_costs', {
        'month_key': testMonth,
        'title': '__ARCHIV_TEST__ Miete',
        'amount_cents': 55000,
      });

      await txn.insert('finance_monthly_costs', {
        'month_key': testMonth,
        'title': '__ARCHIV_TEST__ Internet',
        'amount_cents': 5000,
      });

      // Testkäufe
      final purchases = [
        {
          'title': '__ARCHIV_TEST__ Einkauf',
          'amount_cents': 18000,
          'category': 'Lebensmittel',
          'purchase_date': '2026-09-05',
        },
        {
          'title': '__ARCHIV_TEST__ Kino',
          'amount_cents': 9000,
          'category': 'Freizeit',
          'purchase_date': '2026-09-12',
        },
        {
          'title': '__ARCHIV_TEST__ Bus',
          'amount_cents': 4000,
          'category': 'Mobilität',
          'purchase_date': '2026-09-20',
        },
      ];

      for (final purchase in purchases) {
        await txn.insert('finance_purchases', purchase);
      }
    });
  }
}
