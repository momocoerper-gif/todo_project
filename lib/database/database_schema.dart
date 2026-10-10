class DatabaseSchema {
  static const String createTodosTable = '''
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      due_date TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      priority INTEGER NOT NULL DEFAULT 2
        CHECK(priority BETWEEN 1 AND 3)
    )
  ''';
  static const String createEventsTable = '''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '',
      event_date TEXT NOT NULL,
      start_minute INTEGER,
      end_minute INTEGER,
      is_all_day INTEGER NOT NULL DEFAULT 0,
      recurrence TEXT NOT NULL DEFAULT 'none',
      recurrence_until TEXT
    )
  ''';
    
  static const createFinanceMonthsTable = '''
    CREATE TABLE finance_months (
      month_key TEXT PRIMARY KEY,
      budget_cents INTEGER NOT NULL DEFAULT 0,
      fixed_cents INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const createFinanceFixedCostsTable = '''
    CREATE TABLE finance_fixed_costs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK(amount_cents > 0)
    )
  ''';

  static const createFinancePurchasesTable = '''
    CREATE TABLE finance_purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
      category TEXT NOT NULL,
      purchase_date TEXT NOT NULL
    )
  ''';

  static const createFinanceMonthlyCostsTable = '''
    CREATE TABLE finance_monthly_costs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      month_key TEXT NOT NULL,
      title TEXT NOT NULL,
      amount_cents INTEGER NOT NULL
    )
  ''';

  static const String createEventExceptionsTable = '''
    CREATE TABLE event_exceptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      occurrence_date TEXT NOT NULL,
      is_cancelled INTEGER NOT NULL DEFAULT 0,
      override_date TEXT,
      title TEXT,
      description TEXT,
      location TEXT,
      start_minute INTEGER,
      end_minute INTEGER,
      is_all_day INTEGER,
      UNIQUE(event_id, occurrence_date)
    )
  ''';

}