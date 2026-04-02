// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/app_controller.dart';
import '../database/db_helper.dart';
import '../models/account.dart';
import '../utils/constants.dart';
import 'add_voucher_screen.dart';

const _kPageSize = 30;

class LedgerScreen extends StatefulWidget {
  final Account account;
  const LedgerScreen({super.key, required this.account});
  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<AppController>();

  // ── Paginated rows (sirf ye dikhte hain) ──────────────
  final List<Map<String, dynamic>> _rows = [];

  // ── State flags ────────────────────────────────────────
  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _hasMore = true;

  // ── Pagination tracking ────────────────────────────────
  int _offset = 0;
  double _runningBalance = 0; // last loaded row ka running bal
  int _totalCount = 0;

  // ── Header stats ───────────────────────────────────────
  double _totalDr = 0, _totalCr = 0;

  // ── Date filter ────────────────────────────────────────
  DateTime? _fromDate, _toDate;
  bool get _hasFilter => _fromDate != null || _toDate != null;

  late AnimationController _ac;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _ac.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll: 200px se pehle next page trigger ───────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_pageLoading &&
        _hasMore) {
      _loadNextPage();
    }
  }

  // ── Full reset + first page load ───────────────────────
  Future<void> _init() async {
    setState(() {
      _initialLoading = true;
      _rows.clear();
      _offset = 0;
      _runningBalance = widget.account.openingBalance;
      _hasMore = true;
      _totalDr = 0;
      _totalCr = 0;
    });

    // Parallel: total count + totals + first page
    await Future.wait([_fetchTotals(), _fetchCount()]);

    await _fetchPage(isFirst: true);

    setState(() => _initialLoading = false);
    _ac.forward(from: 0);
  }

  // ── Totals (header stats) ─────────────────────────────
  Future<void> _fetchTotals() async {
    final t = await DBHelper.instance.getAccountLedgerTotals(
      widget.account.id!,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    _totalDr = t['dr'] ?? 0;
    _totalCr = t['cr'] ?? 0;
  }

  // ── Total count (hasMore logic) ───────────────────────
  Future<void> _fetchCount() async {
    _totalCount = await DBHelper.instance.getAccountLedgerCount(
      widget.account.id!,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // ── Fetch one page from DB ─────────────────────────────
  Future<void> _fetchPage({bool isFirst = false}) async {
    final rawRows = await DBHelper.instance.getAccountLedgerPaged(
      widget.account.id!,
      limit: _kPageSize,
      offset: _offset,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    if (rawRows.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }

    // ── Opposite account names resolve + running balance ──
    final processed = <Map<String, dynamic>>[];
    double running = _runningBalance;

    for (final row in rawRows) {
      final amt = (row['amount'] as num).toDouble();
      final isDr = row['type'] == 'debit';
      final txId = row['transactionId'] as int;

      running += isDr ? amt : -amt;

      // Opposite account from cache or DB
      final allEntries = await ctrl.getVoucherEntries(txId); // uses cache
      final oppEntries = allEntries
          .where((e) => e.accountId != widget.account.id)
          .toList();

      String oppName;
      if (oppEntries.isEmpty) {
        oppName = '—';
      } else if (oppEntries.length == 1) {
        oppName = ctrl.accountById(oppEntries.first.accountId)?.name ?? '?';
      } else {
        oppName = oppEntries
            .map((e) => ctrl.accountById(e.accountId)?.name ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
      }

      processed.add({...row, 'running': running, 'oppAcc': oppName});
    }

    setState(() {
      _runningBalance = running; // agle page ke liye save
      _offset += rawRows.length;
      _rows.addAll(processed);
      _hasMore = _offset < _totalCount;
    });
  }

  // ── Load next page ─────────────────────────────────────
  Future<void> _loadNextPage() async {
    if (_pageLoading || !_hasMore) return;
    setState(() => _pageLoading = true);
    await _fetchPage();
    setState(() => _pageLoading = false);
  }

  // ── Date filter bottom sheet ───────────────────────────
  Future<void> _openDateFilter() async {
    DateTime? tempFrom = _fromDate;
    DateTime? tempTo = _toDate;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title + clear
              Row(
                children: [
                  const Text(
                    'Date Range Filter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  if (tempFrom != null || tempTo != null)
                    TextButton(
                      onPressed: () => ss(() {
                        tempFrom = null;
                        tempTo = null;
                      }),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick presets
              const _SectionLabel(label: 'QUICK SELECT'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map(
                      (p) => _QuickChip(
                        label: p.label,
                        isActive: tempFrom == p.from && tempTo == p.to,
                        onTap: () => ss(() {
                          tempFrom = p.from;
                          tempTo = p.to;
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),

              // Custom range
              const _SectionLabel(label: 'CUSTOM RANGE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateBox(
                      label: 'From',
                      date: tempFrom,
                      onTap: () async {
                        final d = await _pickDate(ctx, tempFrom);
                        if (d != null) ss(() => tempFrom = d);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFCCCCCC),
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: _DateBox(
                      label: 'To',
                      date: tempTo,
                      onTap: () async {
                        final d = await _pickDate(ctx, tempTo);
                        if (d != null) ss(() => tempTo = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Apply
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _fromDate = tempFrom;
                      _toDate = tempTo;
                    });
                    _init();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? initial) =>
      showDatePicker(
        context: ctx,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (c, child) => Theme(
          data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
          ),
          child: child!,
        ),
      );

  List<_Preset> get _presets {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      _Preset('Today', today, today),
      _Preset(
        'This Week',
        today.subtract(Duration(days: today.weekday - 1)),
        today,
      ),
      _Preset('This Month', DateTime(now.year, now.month, 1), today),
      _Preset(
        'Last Month',
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0),
      ),
      _Preset('This Year', DateTime(now.year, 1, 1), today),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final bal = ctrl.balances[acc.id] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Column(
        children: [
          // Header
          _Header(
            account: acc,
            balance: bal,
            totalDr: _totalDr,
            totalCr: _totalCr,
            hasFilter: _hasFilter,
            fromDate: _fromDate,
            toDate: _toDate,
            totalRows: _totalCount,
            onBack: () => Get.back(),
            onRefresh: _init,
            onFilter: _openDateFilter,
            onClearFilter: () {
              setState(() {
                _fromDate = null;
                _toDate = null;
              });
              _init();
            },
          ),

          // Table labels
          const _TableHeader(),

          // Body
          Expanded(
            child: _initialLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A237E),
                      strokeWidth: 2.5,
                    ),
                  )
                : _rows.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: _rows.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      // Bottom page loader
                      if (i == _rows.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ),
                        );
                      }
                      return _LedgerRow(
                        row: _rows[i],
                        index: i,
                        animCtrl: _ac,
                        onTap: () async {
                          final txId = _rows[i]['transactionId'] as int;
                          final entries = await ctrl.getVoucherEntries(txId);
                          final voucher = ctrl.vouchers.firstWhereOrNull(
                            (v) => v.id == txId,
                          );
                          if (voucher != null) {
                            await Get.to(
                              () => AddVoucherScreen(
                                existing: voucher,
                                existingEntries: entries,
                              ),
                            );
                            _init();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_ledger',
        onPressed: () async {
          await Get.to(() => const AddVoucherScreen());
          _init();
        },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'New Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        elevation: 3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Account account;
  final double balance, totalDr, totalCr;
  final bool hasFilter;
  final DateTime? fromDate, toDate;
  final int totalRows;
  final VoidCallback onBack, onRefresh, onFilter, onClearFilter;

  const _Header({
    required this.account,
    required this.balance,
    required this.totalDr,
    required this.totalCr,
    required this.hasFilter,
    required this.fromDate,
    required this.toDate,
    required this.totalRows,
    required this.onBack,
    required this.onRefresh,
    required this.onFilter,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isCr = balance < 0;
    final top = MediaQuery.of(context).padding.top;
    final fmt = DateFormat('dd MMM yy');

    return Container(
      padding: EdgeInsets.fromLTRB(0, top, 0, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1560), Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -24,
            child: _Circle(size: 150, opacity: 0.05),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _Circle(size: 110, opacity: 0.04),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (totalRows > 0)
                            Text(
                              '$totalRows entries',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Account type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        account.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    // Filter btn with active dot
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.date_range_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: onFilter,
                        ),
                        if (hasFilter)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1A237E),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active filter pill
              if (hasFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: GestureDetector(
                    onTap: onClearFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.filter_alt_rounded,
                            size: 11,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${fromDate != null ? fmt.format(fromDate!) : '∞'}  →  ${toDate != null ? fmt.format(toDate!) : '∞'}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Balance
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT BALANCE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              fmtAmt(balance.abs()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCr
                                    ? Colors.green.withOpacity(0.25)
                                    : Colors.red.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                isCr ? 'CR' : 'DR',
                                style: TextStyle(
                                  color: isCr
                                      ? Colors.greenAccent.shade100
                                      : Colors.redAccent.shade100,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Stats strip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    _StatItem(
                      'OPENING',
                      fmtAmt(account.openingBalance),
                      Colors.white60,
                    ),
                    _VertDivider(),
                    _StatItem(
                      'TOTAL DR',
                      fmtAmt(totalDr),
                      const Color(0xFFFF8A80),
                    ),
                    _VertDivider(),
                    _StatItem(
                      'TOTAL CR',
                      fmtAmt(totalCr),
                      const Color(0xFF69F0AE),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────
class _Circle extends StatelessWidget {
  final double size, opacity;
  const _Circle({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: Colors.white.withOpacity(0.12),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      color: Color(0xFFAAAAAA),
      letterSpacing: 1,
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Table Header
// ─────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();
  static const _hs = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    color: Color(0xFFAAAAAA),
    letterSpacing: 0.7,
  );

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE8ECF4), width: 1.5)),
      boxShadow: [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(
      children: const [
        SizedBox(width: 54, child: Text('DATE', style: _hs)),
        Expanded(child: Text('PARTICULARS', style: _hs)),
        SizedBox(
          width: 64,
          child: Text(
            'DEBIT',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE53935),
              letterSpacing: 0.7,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            'CREDIT',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF43A047),
              letterSpacing: 0.7,
            ),
          ),
        ),
        SizedBox(
          width: 62,
          child: Text('BAL', textAlign: TextAlign.right, style: _hs),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Ledger Row
// ─────────────────────────────────────────────────────────
class _LedgerRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final int index;
  final AnimationController animCtrl;
  final VoidCallback onTap;

  const _LedgerRow({
    required this.row,
    required this.index,
    required this.animCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDr = row['type'] == 'debit';
    final amt = (row['amount'] as num).toDouble();
    final runBal = row['running'] as double;
    final date = DateTime.tryParse(row['txDate'] ?? '');
    final note = row['txNote'] as String? ?? '';
    final oppAcc = row['oppAcc'] as String;

    // Stagger only first 30 rows
    final delay = (index * 0.025).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: animCtrl,
      curve: Interval(
        delay,
        (delay + 0.35).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: Material(
        color: index.isEven ? Colors.white : const Color(0xFFF7F9FC),
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF1A237E).withOpacity(0.06),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F2F8), width: 0.8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Date
                SizedBox(
                  width: 54,
                  child: date == null
                      ? const Text(
                          '—',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2C54),
                              ),
                            ),
                            Text(
                              DateFormat('yyyy').format(date),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                ),

                // Particulars
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDr
                              ? const Color(0xFFE53935)
                              : const Color(0xFF43A047),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oppAcc,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (note.isNotEmpty)
                              Text(
                                note,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFAAAAAA),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Debit
                SizedBox(
                  width: 64,
                  child: isDr
                      ? Text(
                          fmtAmt(amt),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),

                // Credit
                SizedBox(
                  width: 64,
                  child: !isDr
                      ? Text(
                          fmtAmt(amt),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF43A047),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),

                // Running balance
                SizedBox(
                  width: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmtAmt(runBal.abs()),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: runBal >= 0
                              ? const Color(0xFFE53935)
                              : const Color(0xFF43A047),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (runBal != 0)
                        Text(
                          runBal > 0 ? 'Dr' : 'Cr',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color:
                                (runBal >= 0
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF43A047))
                                    .withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Date filter helpers
// ─────────────────────────────────────────────────────────
class _Preset {
  final String label;
  final DateTime from, to;
  const _Preset(this.label, this.from, this.to);
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1A237E) : const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? const Color(0xFF1A237E) : const Color(0xFFDDDDDD),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFF555555),
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: has
              ? const Color(0xFF1A237E).withOpacity(0.06)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: has
                ? const Color(0xFF1A237E).withOpacity(0.3)
                : const Color(0xFFDDDDDD),
            width: has ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: has ? const Color(0xFF1A237E) : const Color(0xFFAAAAAA),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    has ? DateFormat('dd MMM yy').format(date!) : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: has
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 32,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No entries found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Try changing the date filter',
          style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
        ),
      ],
    ),
  );
}
