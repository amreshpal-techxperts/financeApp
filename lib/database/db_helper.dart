import 'package:financeapp/models/global_keyword.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/tag.dart';
import '../models/tx_voucher.dart';
import '../models/entry.dart';
import '../models/master_account.dart';
import '../models/import_setting.dart';

class DBHelper {
  static Database? _db;
  static final DBHelper instance = DBHelper._internal();
  DBHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'finance_tally_v2.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT NOT NULL,
      type TEXT NOT NULL, 
      openingBalance REAL DEFAULT 0,
      masterAccountId INTEGER,
      phone TEXT, 
      createdAt TEXT NOT NULL,
      FOREIGN KEY (masterAccountId) REFERENCES master_accounts(id) ON DELETE SET NULL
      
      )''');

    await db.execute('''
      CREATE TABLE tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT NOT NULL,
      color TEXT NOT NULL,
      createdAt TEXT NOT NULL)''');

    await db.execute('''
      CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      date TEXT NOT NULL,
      tagId INTEGER,
      note TEXT, source TEXT DEFAULT 'manual',
      masterAccountId INTEGER,
      importHash TEXT UNIQUE,
      createdAt TEXT NOT NULL,
      FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE SET NULL)''');

    await db.execute('''
      CREATE TABLE entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transactionId INTEGER NOT NULL, 
      accountId INTEGER NOT NULL,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT, 
      createdAt TEXT NOT NULL,
      FOREIGN KEY (transactionId) REFERENCES transactions(id) ON DELETE CASCADE,
      FOREIGN KEY (accountId) REFERENCES accounts(id)
      )''');

    await db.execute('''
      CREATE TABLE master_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      accountNumber TEXT,
      bankName TEXT,
      isDefault INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL)''');

    await db.execute('''
      CREATE TABLE import_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      accountNumber TEXT NOT NULL UNIQUE,
      detectedName TEXT NOT NULL,
      setupType TEXT NOT NULL,
      masterAccountId INTEGER,
      customName TEXT NOT NULL,
      createdAt TEXT NOT NULL)''');

    await db.execute('''
      CREATE TABLE account_keywords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      accountId INTEGER NOT NULL,
      keyword TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      UNIQUE(accountId, keyword)
      FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE CASCADE
      )
      ''');

    await db.execute('''
    CREATE TABLE global_keywords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL UNIQUE,
      tagId INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
    )''');

    await _seed(db);
    await _seedGlobalKeywords(db);
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (var a in [
      {'name': 'Cash', 'type': 'cash', 'openingBalance': 0.0},
      {'name': 'SBI Bank', 'type': 'bank', 'openingBalance': 0.0},
    ]) {
      await db.insert('accounts', {...a, 'createdAt': now});
    }

    for (var e in [
      'Food & Dining',
      // 'Shopping',
      // 'Travel',
      // 'Medical',
      // 'Office',
      // 'Entertainment',
      // 'Bills & Utilities',
      'Education',
    ]) {
      await db.insert('accounts', {
        'name': e,
        'type': 'expense',
        'openingBalance': 0.0,
        'createdAt': now,
      });
    }

    for (var t in [
      {'name': 'Food', 'color': '#FF5722'},
      {'name': 'Shopping', 'color': '#2196F3'},
      {'name': 'Travel', 'color': '#4CAF50'},
      {'name': 'Medical', 'color': '#F44336'},
      // {'name': 'Loan', 'color': '#FF9800'},
      // {'name': 'Transfer', 'color': '#607D8B'},
      // {'name': 'Others', 'color': '#9E9E9E'},
    ]) {
      await db.insert('tags', {...t, 'createdAt': now});
    }
  }

  Future<void> _seedGlobalKeywords(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Pehle tags ke ids fetch karo
    final tags = await db.query('tags');
    final tagByName = {
      for (final t in tags) (t['name'] as String).toLowerCase(): t['id'] as int,
    };

    final defaultGlobalKws = [
      {'keyword': 'upi', 'tagName': 'transfer'},
      {'keyword': 'neft', 'tagName': 'transfer'},
      {'keyword': 'imps', 'tagName': 'transfer'},
      {'keyword': 'rtgs', 'tagName': 'transfer'},
      {'keyword': 'transfer', 'tagName': 'transfer'},
      {'keyword': 'atm', 'tagName': 'others'},
      {'keyword': 'cash', 'tagName': 'others'},
    ];

    for (final kw in defaultGlobalKws) {
      final tagId = tagByName[kw['tagName']];
      if (tagId == null) continue;
      await db.insert('global_keywords', {
        'keyword': kw['keyword'],
        'tagId': tagId,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ── ACCOUNTS ────────────────────────────────────
  Future<int> insertAccount(Account a) async =>
      (await database).insert('accounts', a.toMap()..remove('id'));
  Future<List<Account>> getAllAccounts() async {
    final r = await (await database).query(
      'accounts',
      orderBy: 'type ASC, name ASC',
    );
    return r.map(Account.fromMap).toList();
  }

  Future<void> updateAccount(Account a) async => (await database).update(
    'accounts',
    a.toMap(),
    where: 'id=?',
    whereArgs: [a.id],
  );
  Future<void> deleteAccount(int id) async =>
      (await database).delete('accounts', where: 'id=?', whereArgs: [id]);

  Future<double> getAccountBalance(int id) async {
    final db = await database;
    final acc = (await db.query(
      'accounts',
      where: 'id=?',
      whereArgs: [id],
    )).firstOrNull;
    if (acc == null) return 0;
    final opening = (acc['openingBalance'] as num).toDouble();
    final dr =
        ((await db.rawQuery(
                  'SELECT COALESCE(SUM(amount),0) as t FROM entries WHERE accountId=? AND type="debit"',
                  [id],
                )).first['t']
                as num)
            .toDouble();
    final cr =
        ((await db.rawQuery(
                  'SELECT COALESCE(SUM(amount),0) as t FROM entries WHERE accountId=? AND type="credit"',
                  [id],
                )).first['t']
                as num)
            .toDouble();
    return opening + dr - cr;
  }

  Future<Map<int, double>> getAllBalances() async {
    final accounts = await getAllAccounts();
    final Map<int, double> result = {};
    for (var a in accounts) {
      result[a.id!] = await getAccountBalance(a.id!);
    }
    return result;
  }

  // ── TAGS ────────────────────────────────────────
  Future<int> insertTag(Tag t) async =>
      (await database).insert('tags', t.toMap()..remove('id'));
  Future<List<Tag>> getAllTags() async {
    final r = await (await database).query('tags', orderBy: 'name ASC');
    return r.map(Tag.fromMap).toList();
  }

  Future<void> updateTag(Tag t) async => (await database).update(
    'tags',
    t.toMap(),
    where: 'id=?',
    whereArgs: [t.id],
  );
  Future<void> deleteTag(int id) async =>
      (await database).delete('tags', where: 'id=?', whereArgs: [id]);

  // ── VOUCHERS ────────────────────────────────────
  Future<int> insertVoucher(TxVoucher v, List<Entry> entries) async {
    final db = await database;
    int vId = 0;
    await db.transaction((txn) async {
      vId = await txn.insert('transactions', v.toMap()..remove('id'));
      for (var e in entries) {
        e.transactionId = vId;
        await txn.insert('entries', e.toMap()..remove('id'));
      }
    });
    return vId;
  }

  Future<void> updateVoucher(TxVoucher v, List<Entry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        v.toMap(),
        where: 'id=?',
        whereArgs: [v.id],
      );
      await txn.delete('entries', where: 'transactionId=?', whereArgs: [v.id]);
      for (var e in entries) {
        e.transactionId = v.id!;
        await txn.insert('entries', e.toMap()..remove('id'));
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllVouchersWithEntries() async {
    final db = await database;

    final result = await db.rawQuery('''
  SELECT
    v.date,
    v.note,
    e.amount
  FROM transactions v
  INNER JOIN entries e ON e.transactionId = v.id
  WHERE e.rowid = (
    SELECT MIN(e2.rowid)
    FROM entries e2
    WHERE e2.transactionId = v.id
  )
  ORDER BY v.id DESC
''');

    return result;
  }

  Future<void> deleteVoucher(int id) async =>
      (await database).delete('transactions', where: 'id=?', whereArgs: [id]);

  Future<List<TxVoucher>> getVouchers({String? search}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (search != null && search.isNotEmpty) {
      where += ' AND note LIKE ?';
      args.add('%$search%');
    }
    final r = await db.query(
      'transactions',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, createdAt DESC',
    );
    return r.map(TxVoucher.fromMap).toList();
  }

  Future<List<Entry>> getEntriesForVoucher(int vId) async {
    final r = await (await database).query(
      'entries',
      where: 'transactionId=?',
      whereArgs: [vId],
    );
    return r.map(Entry.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getAccountLedger(int accountId) async {
    return (await database).rawQuery(
      '''
      SELECT e.*, t.date as txDate, t.note as txNote, t.id as txId
      FROM entries e JOIN transactions t ON e.transactionId=t.id
      WHERE e.accountId=? ORDER BY t.date ASC, t.createdAt ASC''',
      [accountId],
    );
  }

  Future<Map<String, double>> getTagWiseExpenses() async {
    final r = await (await database).rawQuery('''
      SELECT tg.name, COALESCE(SUM(e.amount),0) as total
      FROM entries e JOIN tags tg ON e.tagId=tg.id
      JOIN accounts a ON e.accountId=a.id
      WHERE a.type='expense' AND e.type='debit'
      GROUP BY tg.name ORDER BY total DESC''');
    return {
      for (var row in r)
        row['name'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenses() async {
    return (await database).rawQuery('''
      SELECT strftime('%Y-%m', t.date) as month, COALESCE(SUM(e.amount),0) as total
      FROM entries e JOIN transactions t ON e.transactionId=t.id
      JOIN accounts a ON e.accountId=a.id
      WHERE a.type='expense' AND e.type='debit'
      GROUP BY month ORDER BY month ASC''');
  }

  Future<int> bulkInsertVouchers(
    List<TxVoucher> vouchers,
    List<List<Entry>> entriesList,
  ) async {
    final db = await database;
    int insertedCount = 0;

    await db.transaction((txn) async {
      for (int i = 0; i < vouchers.length; i++) {
        final vId = await txn.insert(
          'transactions',
          vouchers[i].toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (vId == 0) continue;

        insertedCount++;
        for (final e in entriesList[i]) {
          final map = e.toMap();
          map['transactionId'] = vId;
          await txn.insert('entries', map);
        }
      }
    });

    return insertedCount;
  }

  // ── MASTER ACCOUNTS ─────────────────────────────
  Future<int> insertMasterAccount(MasterAccount ma) async {
    final db = await database;
    if (ma.isDefault) await db.update('master_accounts', {'isDefault': 0});
    return db.insert('master_accounts', ma.toMap()..remove('id'));
  }

  Future<List<MasterAccount>> getMasterAccounts() async {
    final r = await (await database).query(
      'master_accounts',
      orderBy: 'isDefault DESC, name ASC',
    );
    return r.map(MasterAccount.fromMap).toList();
  }

  Future<void> updateMasterAccount(MasterAccount ma) async {
    final db = await database;
    if (ma.isDefault) await db.update('master_accounts', {'isDefault': 0});
    await db.update(
      'master_accounts',
      ma.toMap(),
      where: 'id=?',
      whereArgs: [ma.id],
    );
  }

  Future<void> setDefaultMA(int id) async {
    final db = await database;
    await db.update('master_accounts', {'isDefault': 0});
    await db.update(
      'master_accounts',
      {'isDefault': 1},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMasterAccount(int id) async {
    final db = await database;
    await db.update(
      'import_settings',
      {'masterAccountId': null},
      where: 'masterAccountId=?',
      whereArgs: [id],
    );
    await db.delete('master_accounts', where: 'id=?', whereArgs: [id]);
  }

  // ── IMPORT SETTINGS ──────────────────────────────
  Future<void> upsertImportSetting(ImportSetting s) async =>
      (await database).insert(
        'import_settings',
        s.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
  Future<ImportSetting?> getImportSetting(String accNo) async {
    final r = await (await database).query(
      'import_settings',
      where: 'accountNumber=?',
      whereArgs: [accNo],
    );
    return r.isEmpty ? null : ImportSetting.fromMap(r.first);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // db_helper.dart mein YEH METHODS ADD karo (existing methods ke saath)
  // ─────────────────────────────────────────────────────────────────────────────

  // ── 1. Total row count (hasMore ke liye) ──────────────────────────────────────
  Future<int> getAccountLedgerCount(
    int accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;

    String where = 'e.accountId = ?';
    final args = <dynamic>[accountId];

    if (fromDate != null) {
      where += ' AND t.date >= ?';
      args.add(fromDate.toIso8601String().substring(0, 10));
    }
    if (toDate != null) {
      where += ' AND t.date <= ?';
      args.add(toDate.toIso8601String().substring(0, 10));
    }

    final result = await db.rawQuery('''
    SELECT COUNT(*) as cnt
    FROM entries e
    INNER JOIN transactions t ON e.transactionId = t.id
    WHERE $where
  ''', args);

    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── 2. Running balance up to a given offset ───────────────────────────────────
  //    Yeh naya page shuru karne se pehle "kahan se balance continue kare"
  //    jaanne ke liye use hoga.
  Future<double> getRunningBalanceBeforeOffset(
    int accountId,
    double openingBalance, {
    int offset = 0,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (offset == 0) return openingBalance;

    final db = await database;

    String where = 'e.accountId = ?';
    final args = <dynamic>[accountId];

    if (fromDate != null) {
      where += ' AND t.date >= ?';
      args.add(fromDate.toIso8601String().substring(0, 10));
    }
    if (toDate != null) {
      where += ' AND t.date <= ?';
      args.add(toDate.toIso8601String().substring(0, 10));
    }

    // Pehle `offset` rows ka net effect calculate karo
    final rows = await db.rawQuery(
      '''
    SELECT e.type, e.amount
    FROM entries e
    INNER JOIN transactions t ON e.transactionId = t.id
    WHERE $where
    ORDER BY t.date ASC, t.id ASC
    LIMIT ?
  ''',
      [...args, offset],
    );

    double running = openingBalance;
    for (final row in rows) {
      final amt = (row['amount'] as num).toDouble();
      running += row['type'] == 'debit' ? amt : -amt;
    }
    return running;
  }

  // ── 3. Paginated ledger rows ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAccountLedgerPaged(
    int accountId, {
    required int limit,
    required int offset,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;

    String where = 'e.accountId = ?';
    final args = <dynamic>[accountId];

    if (fromDate != null) {
      where += ' AND t.date >= ?';
      args.add(fromDate.toIso8601String().substring(0, 10));
    }
    if (toDate != null) {
      where += ' AND t.date <= ?';
      args.add(toDate.toIso8601String().substring(0, 10));
    }

    args.addAll([limit, offset]);

    return db.rawQuery('''
    SELECT
      e.id,
      e.type,
      e.amount,
      t.id   AS transactionId,
      t.date AS txDate,
      t.note AS txNote
    FROM entries e
    INNER JOIN transactions t ON e.transactionId = t.id
    WHERE $where
    ORDER BY t.date ASC, t.id ASC
    LIMIT ? OFFSET ?
  ''', args);
  }

  // ── 4. DR/CR totals for the filtered range (header stats ke liye) ─────────────
  Future<Map<String, double>> getAccountLedgerTotals(
    int accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;

    String where = 'e.accountId = ?';
    final args = <dynamic>[accountId];

    if (fromDate != null) {
      where += ' AND t.date >= ?';
      args.add(fromDate.toIso8601String().substring(0, 10));
    }
    if (toDate != null) {
      where += ' AND t.date <= ?';
      args.add(toDate.toIso8601String().substring(0, 10));
    }

    final rows = await db.rawQuery('''
    SELECT e.type, SUM(e.amount) as total
    FROM entries e
    INNER JOIN transactions t ON e.transactionId = t.id
    WHERE $where
    GROUP BY e.type
  ''', args);

    double dr = 0, cr = 0;
    for (final r in rows) {
      final amt = (r['total'] as num?)?.toDouble() ?? 0;
      if (r['type'] == 'debit')
        dr = amt;
      else
        cr = amt;
    }
    return {'dr': dr, 'cr': cr};
  }

  //   Future<void> updateAccountKeywords(int accountId, List<String> keywords) async {
  //   await (await database).update(
  //     'accounts',
  //     {'keywords': keywords.join(',')},
  //     where: 'id=?',
  //     whereArgs: [accountId],
  //   );
  // }

  Future<void> updateAccountKeywords(
    int accountId,
    List<String> newKeywords,
  ) async {
    final db = await database;

    print("account id = $accountId");
    print("new keywords = $newKeywords");

    for (final kw in newKeywords) {
      final k = kw.trim().toLowerCase();

      if (k.length < 3) continue;

      try {
        await db.insert(
          'account_keywords',
          {
            'accountId': accountId,
            'keyword': k,
            'createdAt': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore, // duplicate skip
        );
      } catch (_) {
        // ignore error
      }
    }
  }

  Future<void> bulkUpdateKeywords(Map<int, List<String>> keywordsToAdd) async {
    if (keywordsToAdd.isEmpty) return;
    for (final entry in keywordsToAdd.entries) {
      await updateAccountKeywords(entry.key, entry.value);
    }
  }

  Future<int> insertGlobalKeyword(GlobalKeyword gk) async {
    return (await database).insert(
      'global_keywords',
      gk.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Sabhi global keywords fetch karo
  Future<List<GlobalKeyword>> getAllGlobalKeywords() async {
    final r = await (await database).query(
      'global_keywords',
      orderBy: 'keyword ASC',
    );
    return r.map(GlobalKeyword.fromMap).toList();
  }

  /// Ek tag ke saare global keywords
  Future<List<GlobalKeyword>> getGlobalKeywordsForTag(int tagId) async {
    final r = await (await database).query(
      'global_keywords',
      where: 'tagId = ?',
      whereArgs: [tagId],
      orderBy: 'keyword ASC',
    );
    return r.map(GlobalKeyword.fromMap).toList();
  }

  /// Global keyword update karo
  Future<void> updateGlobalKeyword(GlobalKeyword gk) async =>
      (await database).update(
        'global_keywords',
        gk.toMap(),
        where: 'id = ?',
        whereArgs: [gk.id],
      );

  /// Global keyword delete karo by id
  Future<void> deleteGlobalKeyword(int id) async => (await database).delete(
    'global_keywords',
    where: 'id = ?',
    whereArgs: [id],
  );

  /// Keyword string se delete karo
  Future<void> deleteGlobalKeywordByString(String keyword) async =>
      (await database).delete(
        'global_keywords',
        where: 'keyword = ?',
        whereArgs: [keyword.toLowerCase().trim()],
      );

  /// Map return karo: tagId → [keywords] (import parser ke liye)
  Future<Map<int, List<String>>> getGlobalKeywordsMap() async {
    final all = await getAllGlobalKeywords();
    final map = <int, List<String>>{};
    for (final gk in all) {
      map.putIfAbsent(gk.tagId, () => []).add(gk.keyword.toLowerCase().trim());
    }
    return map;
  }

  /// Bulk upsert — import ke baad keywords save karne ke liye
  Future<void> bulkUpsertGlobalKeywords(List<GlobalKeyword> keywords) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final gk in keywords) {
        await txn.insert(
          'global_keywords',
          gk.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<String>> getKeywordsForAccount(int accountId) async {
    final rows = await (await database).query(
      'account_keywords',
      columns: ['keyword'],
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => r['keyword'] as String).toList();
  }

  Future<Map<int, List<String>>> getAllAccountKeywordsMap() async {
    final rows = await (await database).query(
      'account_keywords',
      columns: ['accountId', 'keyword'],
      orderBy: 'accountId ASC, createdAt ASC',
    );
    final map = <int, List<String>>{};
    for (final r in rows) {
      final id = r['accountId'] as int;
      map.putIfAbsent(id, () => []).add(r['keyword'] as String);
    }

    print("map = $map");
    return map;
  }

  Future<void> setAccountKeywords(int accountId, List<String> keywords) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete(
        'account_keywords',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );
      for (final kw in keywords) {
        final k = kw.trim().toLowerCase();
        if (k.length < 2) continue;
        await txn.insert('account_keywords', {
          'accountId': accountId,
          'keyword': k,
          'createdAt': now,
        });
      }
    });
  }

  Future<void> addKeywordsForAccount(
    int accountId,
    List<String> newKeywords,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Existing fetch karo
    final existing = (await getKeywordsForAccount(accountId)).toSet();

    await db.transaction((txn) async {
      for (final kw in newKeywords) {
        final k = kw.trim().toLowerCase();
        if (k.length < 2 || existing.contains(k)) continue;
        await txn.insert('account_keywords', {
          'accountId': accountId,
          'keyword': k,
          'createdAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        existing.add(k);
      }
    });
  }

  Future<void> bulkAddKeywords(Map<int, List<String>> keywordsMap) async {
    for (final entry in keywordsMap.entries) {
      await addKeywordsForAccount(entry.key, entry.value);
    }
  }

  Future<void> deleteAccountKeyword(int accountId, String keyword) async =>
      (await database).delete(
        'account_keywords',
        where: 'accountId = ? AND keyword = ?',
        whereArgs: [accountId, keyword.toLowerCase().trim()],
      );

  Future<List<Map<String, dynamic>>> getAccountLedgerWithKeyword(
    int accountId,
    List<String> keywords, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;

    final keywordConditions = keywords
        .map((k) => "LOWER(t.note) LIKE '%${k.toLowerCase()}%'")
        .join(" OR ");

    final result = await db.rawQuery(
      '''
    SELECT DISTINCT t.id, t.date, t.note
    FROM transactions t
    LEFT JOIN entries e ON e.transactionId = t.id
    WHERE (
      e.accountId = ?
      ${keywords.isNotEmpty ? "OR ($keywordConditions)" : ""}
    )
    ORDER BY t.date DESC
    LIMIT $limit OFFSET $offset
  ''',
      [accountId],
    );

    return result;
  }
}
