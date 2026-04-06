// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import '../../database/db_helper.dart';
import '../../models/global_keyword.dart';
import '../../utils/constants.dart';

/// Global Keywords manage karne ki screen.
/// Yahan user dekh sakta hai, add/delete kar sakta hai
/// global (tier-3) keywords jo Tags se linked hain.
class GlobalKeywordsScreen extends StatefulWidget {
  const GlobalKeywordsScreen({super.key});

  @override
  State<GlobalKeywordsScreen> createState() => _GlobalKeywordsScreenState();
}

class _GlobalKeywordsScreenState extends State<GlobalKeywordsScreen> {
  final ctrl = Get.find<AppController>();
  List<GlobalKeyword> _globalKws = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _globalKws = await DBHelper.instance.getAllGlobalKeywords();
    setState(() => _loading = false);
  }

  // Group keywords by tagId
  Map<int, List<GlobalKeyword>> get _grouped {
    final map = <int, List<GlobalKeyword>>{};
    for (final gk in _globalKws) {
      map.putIfAbsent(gk.tagId, () => []).add(gk);
    }
    return map;
  }

  Future<void> _addKeyword(int tagId) async {
    final ctrl2 = TextEditingController();
    final saved = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Global Keyword',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl2,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'e.g. upi, atm, neft...',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => Get.back(result: v.trim().toLowerCase()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Get.back(result: ctrl2.text.trim().toLowerCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (saved == null || saved.isEmpty) return;

    // Duplicate check
    if (_globalKws.any((g) => g.keyword == saved)) {
      Get.snackbar(
        'Already exists',
        '"$saved" is already a global keyword',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    await DBHelper.instance.insertGlobalKeyword(GlobalKeyword(
      keyword: saved,
      tagId: tagId,
      createdAt: DateTime.now().toIso8601String(),
    ));
    _load();
  }

  Future<void> _delete(GlobalKeyword gk) async {
    await DBHelper.instance.deleteGlobalKeyword(gk.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Global Keywords',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Info banner ──────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Global keywords (Tier 3) match transaction descriptions and assign a Tag. '
                          'Examples: "upi" → Transfer, "atm" → Others.',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Priority legend ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _PriorityBadge(
                        label: 'P1 Account',
                        color: AppColors.credit,
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(
                        label: 'P2 Party',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(
                        label: 'P3 Global ← YOU ARE HERE',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),

                // ── Keywords grouped by tag ──────────────────────────
                Expanded(
                  child: ctrl.tags.isEmpty
                      ? const Center(
                          child: Text(
                            'No tags found. Create tags first.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: ctrl.tags.length,
                          itemBuilder: (_, i) {
                            final tag = ctrl.tags[i];
                            final kws = _grouped[tag.id] ?? [];
                            final tc = hexColor(tag.color);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: tc.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tag header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tc.withOpacity(0.08),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: tc,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tag.name,
                                          style: TextStyle(
                                            color: tc,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () => _addKeyword(tag.id!),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tc.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  size: 13,
                                                  color: tc,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Add',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: tc,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Keywords chips
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: kws.isEmpty
                                        ? Text(
                                            'No global keywords yet. Tap Add.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: kws.map((gk) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.only(
                                                  left: 10,
                                                  right: 4,
                                                  top: 5,
                                                  bottom: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: tc.withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: tc.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      gk.keyword,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: tc,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _delete(gk),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: tc.withOpacity(
                                                            0.15,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 10,
                                                          color: tc,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}