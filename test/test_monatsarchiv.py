"""Isolierter SQL-Regressionstest der Finanzlogik. Keine App-Dateien werden geöffnet.
Start: python tests/test_monatsarchiv.py (vom entpackten ZIP-Hauptordner)
"""
import sqlite3
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
schema_dart = (ROOT / 'lib/database/database_schema.dart').read_text(encoding='utf-8')
helper_dart = (ROOT / 'lib/database/database_helper.dart').read_text(encoding='utf-8')

def sql_constant(name):
    match = re.search(rf'\b{name}\s*=\s*\'\'\'(.*?)\'\'\'', schema_dart, re.S)
    assert match, f'Tabellendefinition fehlt: {name}'
    return match.group(1)

# Exakt dieselben CREATE TABLE Statements wie im Projekt.
con = sqlite3.connect(':memory:')
con.row_factory = sqlite3.Row
for name in ('createFinanceMonthsTable', 'createFinanceFixedCostsTable',
             'createFinancePurchasesTable', 'createFinanceMonthlyCostsTable'):
    con.execute(sql_constant(name))

# Alle Werte in CENT, bewusst nachvollziehbar.
months = [
    ('2026-08', 150000, 60000),
    ('2026-09', 150000, 65000),
    ('2026-10', 160000, 65000),
]
con.executemany('INSERT INTO finance_months VALUES (?, ?, ?)', months)
con.executemany('INSERT INTO finance_purchases '
                '(title, amount_cents, category, purchase_date) VALUES (?,?,?,?)', [
    ('August Supermarkt', 40000, 'Lebensmittel', '2026-08-12'),
    ('September Einkauf', 50000, 'Lebensmittel', '2026-09-04'),
    ('September Freizeit', 20000, 'Freizeit', '2026-09-17'),
    ('Oktober Einkauf', 30000, 'Lebensmittel', '2026-10-06'),
])
for key, _, fixed in months:
    con.execute('INSERT INTO finance_monthly_costs (month_key, title, amount_cents) '
                'VALUES (?, ?, ?)', (key, 'Gespeicherte Fixkosten', fixed))
con.execute('INSERT INTO finance_fixed_costs (title,amount_cents) VALUES (?,?)',
            ('Miete', 65000))

# Abfrage DIREKT aus getFinanceArchive() extrahieren, nicht nachprogrammiert.
match = re.search(r'Future<List<Map<String, Object\?>>> getFinanceArchive\(\).*?return db\.rawQuery\(\'\'\'(.*?)\'\'\', \[currentKey\]\);', helper_dart, re.S)
assert match, 'getFinanceArchive SQL nicht gefunden'
archive_sql = match.group(1)

def archive(as_of):
    return [dict(row) for row in con.execute(archive_sql, (as_of,)).fetchall()]

rows = archive('2026-10')
assert [r['month_key'] for r in rows] == ['2026-09', '2026-08'], rows
assert (rows[0]['budget_cents'], rows[0]['fixed_cents'], rows[0]['spent_cents']) == (150000,65000,70000)
assert (rows[1]['budget_cents'], rows[1]['fixed_cents'], rows[1]['spent_cents']) == (150000,60000,40000)
assert rows[0]['budget_cents'] - rows[0]['fixed_cents'] - rows[0]['spent_cents'] == 15000
assert rows[1]['budget_cents'] - rows[1]['fixed_cents'] - rows[1]['spent_cents'] == 50000
print('OK: Oktober-Archiv enthält nur August/September mit korrekten Beträgen.')

# Fixkosten am aktuellen Monat ändern, Snapshot neu erzeugen.
con.execute('UPDATE finance_fixed_costs SET amount_cents = 70000 WHERE title = ?', ('Miete',))
con.execute('DELETE FROM finance_monthly_costs WHERE month_key = ?', ('2026-10',))
con.execute('INSERT INTO finance_monthly_costs (month_key,title,amount_cents) VALUES (?,?,?)',
            ('2026-10', 'Miete', 70000))
con.execute('UPDATE finance_months SET fixed_cents = 70000 WHERE month_key = ?', ('2026-10',))
assert con.execute('SELECT fixed_cents FROM finance_months WHERE month_key = ?', ('2026-09',)).fetchone()[0] == 65000
assert con.execute('SELECT fixed_cents FROM finance_months WHERE month_key = ?', ('2026-08',)).fetchone()[0] == 60000
assert archive('2026-10') == rows
print('OK: Fixkostenänderung im Oktober lässt die archivierten Monate unverändert.')

# Monat wird archiviert, sobald die Zeitgrenze auf November wechselt.
november = archive('2026-11')
assert [r['month_key'] for r in november] == ['2026-10', '2026-09', '2026-08']
assert november[0]['fixed_cents'] == 70000
assert november[0]['spent_cents'] == 30000
assert november[0]['budget_cents'] - november[0]['fixed_cents'] - november[0]['spent_cents'] == 60000
print('OK: Im November wird Oktober mit Restbudget 600,00 € archiviert.')

# Wichtige Grenze: Leere Monate entstehen NICHT automatisch im Archiv.
assert all(r['month_key'] != '2026-11' for r in november)
print('OK: Leere, nie angelegte Monatszeilen werden nicht erfunden.')
print('Alle SQL-Archivtests bestanden. Keine echten App-Daten verändert.')
