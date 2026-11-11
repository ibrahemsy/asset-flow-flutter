import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';

class CustodyScreen extends StatefulWidget {
  const CustodyScreen({super.key});

  @override
  State<CustodyScreen> createState() => _CustodyScreenState();
}

class _CustodyScreenState extends State<CustodyScreen> {
  String _search = '';
  String _searchMode = 'all'; // all | nationalId | material | name

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var cards = app.custodyCards;

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      cards = cards.where((c) {
        switch (_searchMode) {
          case 'nationalId':
            return c.nationalId.toLowerCase().contains(q);
          case 'material':
            return c.items.any((item) =>
                item.name.toLowerCase().contains(q) ||
                item.description.toLowerCase().contains(q) ||
                item.serialNumber.toLowerCase().contains(q) ||
                item.itemCode.toLowerCase().contains(q) ||
                item.barcode.toLowerCase().contains(q));
          case 'name':
            return c.employeeName.toLowerCase().contains(q);
          default:
            return c.employeeName.toLowerCase().contains(q) ||
                c.nationalId.toLowerCase().contains(q) ||
                c.cardNumber.toLowerCase().contains(q) ||
                c.jobTitle.toLowerCase().contains(q) ||
                c.items.any((item) =>
                    item.name.toLowerCase().contains(q) ||
                    item.description.toLowerCase().contains(q) ||
                    item.serialNumber.toLowerCase().contains(q));
        }
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: _hint(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _search = ''))
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _modeChip(Icons.manage_search_rounded, 'الكل', 'all'),
                _modeChip(Icons.badge_rounded, 'الهوية', 'nationalId'),
                _modeChip(Icons.inventory_2_rounded, 'المادة', 'material'),
                _modeChip(Icons.person_rounded, 'الاسم', 'name'),
              ],
            ),
          ),
          if (_searchMode == 'nationalId' && _search.trim().isNotEmpty && cards.isNotEmpty)
            _identityBanner(cards),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(AppIcons.custody, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text(_search.isEmpty ? 'لا بطاقات عهدة' : 'لا نتائج', style: const TextStyle(color: AppTheme.textSecondary)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
                    itemCount: cards.length,
                    itemBuilder: (_, i) {
                      final c = cards[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: const SectionIcon(icon: AppIcons.custody, color: Color(0xFF7C3AED), size: 42),
                          title: Text(c.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            [if (c.nationalId.isNotEmpty) 'هوية: ${c.nationalId}', c.cardNumber, if (c.jobTitle.isNotEmpty) c.jobTitle].join(' • '),
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${c.items.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                            const Text('مواد', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          ]),
                          onTap: () => _showDetails(context, c, app),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null, app),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _hint() {
    switch (_searchMode) {
      case 'nationalId': return 'ابحث برقم الهوية الوطنية...';
      case 'material': return 'اسم المادة أو الوصف أو السيريال...';
      case 'name': return 'اسم الموظف...';
      default: return 'بحث: اسم، هوية، مادة، رقم بطاقة...';
    }
  }

  Widget _modeChip(IconData icon, String label, String mode) {
    final selected = _searchMode == mode;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.primary),
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _searchMode = mode),
        selectedColor: AppTheme.primary,
      ),
    );
  }

  Widget _identityBanner(List<CustodyCard> cards) {
    final items = cards.expand((c) => c.items).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        const SectionIcon(icon: Icons.badge_rounded, color: AppTheme.primary, size: 40),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cards.first.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('هوية: ${cards.first.nationalId.isNotEmpty ? cards.first.nationalId : _search}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
          Text('${cards.length} بطاقة • ${items.length} مادة مستلمة', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  void _showDetails(BuildContext context, CustodyCard c, AppProvider app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (_, ctrl) => StatefulBuilder(builder: (ctx, setModal) {
            return ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  const SectionIcon(icon: AppIcons.custody, color: Color(0xFF7C3AED), size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.employeeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (c.nationalId.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.badge_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(c.nationalId, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      ]),
                  ])),
                ]),
                const Divider(height: 20),
                _line(Icons.tag_rounded, 'البطاقة', c.cardNumber),
                _line(Icons.work_rounded, 'الوظيفة', c.jobTitle),
                _line(Icons.apartment_rounded, 'الدائرة', c.department),
                _line(Icons.account_tree_rounded, 'الشعبة', c.division),
                _line(Icons.meeting_room_rounded, 'المكتب', c.officeOrCenter),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('المواد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addItem(context, c, app, setModal),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('مادة'),
                  ),
                ]),
                ...c.items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
                            child: Text('${item.no}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            icon: const Icon(Icons.add_a_photo_rounded, size: 20, color: AppTheme.primary),
                            tooltip: 'رفع صورة',
                            onPressed: () => _addPhoto(context, c, idx, app, setModal),
                          ),
                        ]),
                        if (item.description.isNotEmpty)
                          Text(item.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 8, children: [
                          if (item.serialNumber.isNotEmpty)
                            IconChip(icon: Icons.qr_code_rounded, label: item.serialNumber, color: AppTheme.primary),
                          IconChip(icon: Icons.numbers_rounded, label: '×${item.quantity}', color: AppTheme.accent),
                        ]),
                        if (item.imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: item.imageUrls.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (_, i) {
                                final url = item.imageUrls[i];
                                return GestureDetector(
                                  onTap: () => _fullImage(context, url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _img(url, 72, 72),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(context); _showForm(context, c, app); },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('تعديل'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                    onPressed: () async {
                      final msg = await app.deleteCustodyCard(c.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحذف')));
                      }
                    },
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('حذف'),
                  )),
                ]),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _addPhoto(BuildContext context, CustodyCard card, int itemIndex, AppProvider app, StateSetter setModal) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('الكاميرا'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('المعرض'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ])),
      ),
    );
    if (source == null) return;
    final xfile = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 70);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final items = List<CustodyCardItem>.from(card.items);
    final old = items[itemIndex];
    items[itemIndex] = old.copyWith(imageUrls: [...old.imageUrls, dataUrl]);
    final updated = _copyCard(card, items: items);
    final msg = await app.saveCustodyCard(updated);
    setModal(() {});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تمت إضافة الصورة')));
    }
  }

  void _addItem(BuildContext context, CustodyCard card, AppProvider app, StateSetter setModal) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مادة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المادة *')),
          const SizedBox(height: 8),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف / المواصفات')),
          const SizedBox(height: 8),
          TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'الرقم التسلسلي')),
          const SizedBox(height: 8),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'الكمية'), keyboardType: TextInputType.number),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final newItem = CustodyCardItem(
              id: const Uuid().v4(),
              no: card.items.length + 1,
              name: nameCtrl.text.trim(),
              description: descCtrl.text.trim(),
              unit: 'قطعة',
              quantity: int.tryParse(qtyCtrl.text) ?? 1,
              serialNumber: serialCtrl.text.trim(),
              barcode: '',
              itemCode: '',
              receiptDetails: '',
              receiptDate: DateTime.now().toIso8601String().split('T').first,
              returnDetails: '',
              custodyNumber: card.cardNumber,
              returnDate: '',
              balance: int.tryParse(qtyCtrl.text) ?? 1,
              notes: '',
            );
            Navigator.pop(context);
            final msg = await app.saveCustodyCard(_copyCard(card, items: [...card.items, newItem]));
            setModal(() {});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تمت الإضافة')));
            }
          }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, CustodyCard? existing, AppProvider app) {
    final nameCtrl = TextEditingController(text: existing?.employeeName);
    final nationalIdCtrl = TextEditingController(text: existing?.nationalId);
    final jobCtrl = TextEditingController(text: existing?.jobTitle);
    final cardNoCtrl = TextEditingController(text: existing?.cardNumber);
    final deptCtrl = TextEditingController(text: existing?.department ?? 'دائرة الاتصالات');
    final divisionCtrl = TextEditingController(text: existing?.division);
    final officeCtrl = TextEditingController(text: existing?.officeOrCenter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'بطاقة عهدة جديدة' : 'تعديل بطاقة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(controller: cardNoCtrl, decoration: const InputDecoration(labelText: 'رقم البطاقة *', prefixIcon: Icon(Icons.tag_rounded))),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الموظف *', prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 10),
            TextField(controller: nationalIdCtrl, decoration: const InputDecoration(labelText: 'الرقم الوطني / الهوية *', prefixIcon: Icon(Icons.badge_rounded), hintText: 'مثال: 01234567890'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'الوظيفة', prefixIcon: Icon(Icons.work_rounded))),
            const SizedBox(height: 10),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'الدائرة', prefixIcon: Icon(Icons.apartment_rounded))),
            const SizedBox(height: 10),
            TextField(controller: divisionCtrl, decoration: const InputDecoration(labelText: 'الشعبة')),
            const SizedBox(height: 10),
            TextField(controller: officeCtrl, decoration: const InputDecoration(labelText: 'المكتب')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || cardNoCtrl.text.trim().isEmpty) return;
              final now = DateTime.now().toIso8601String();
              final card = CustodyCard(
                id: existing?.id ?? const Uuid().v4(),
                cardNumber: cardNoCtrl.text.trim(),
                employeeName: nameCtrl.text.trim(),
                nationalId: nationalIdCtrl.text.trim(),
                jobTitle: jobCtrl.text.trim(),
                directorate: existing?.directorate ?? 'وزارة الطوارئ وإدارة الكوارث',
                workCenter: existing?.workCenter ?? '',
                department: deptCtrl.text.trim(),
                division: divisionCtrl.text.trim(),
                officeOrCenter: officeCtrl.text.trim(),
                creationDate: existing?.creationDate ?? now.split('T').first,
                items: existing?.items ?? [],
                employeeSignature: existing?.employeeSignature ?? '',
                deliveryOfficerSignature: existing?.deliveryOfficerSignature ?? '',
                deptHeadSignature: existing?.deptHeadSignature ?? '',
                warehouseKeeperSignature: existing?.warehouseKeeperSignature ?? '',
                adminEndorsement: existing?.adminEndorsement ?? '',
                endorsementDate: existing?.endorsementDate ?? '',
                status: existing?.status ?? 'active',
                createdAt: existing?.createdAt ?? now,
                updatedAt: now,
                createdBy: app.currentUser?.email,
              );
              final msg = await app.saveCustodyCard(card);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'تم الحفظ')));
              }
            }, child: const Text('حفظ')),
            const SizedBox(height: 20),
          ])),
        ),
      ),
    );
  }

  CustodyCard _copyCard(CustodyCard c, {List<CustodyCardItem>? items}) {
    return CustodyCard(
      id: c.id,
      cardNumber: c.cardNumber,
      employeeName: c.employeeName,
      nationalId: c.nationalId,
      jobTitle: c.jobTitle,
      directorate: c.directorate,
      workCenter: c.workCenter,
      department: c.department,
      division: c.division,
      officeOrCenter: c.officeOrCenter,
      creationDate: c.creationDate,
      items: items ?? c.items,
      employeeSignature: c.employeeSignature,
      deliveryOfficerSignature: c.deliveryOfficerSignature,
      deptHeadSignature: c.deptHeadSignature,
      warehouseKeeperSignature: c.warehouseKeeperSignature,
      adminEndorsement: c.adminEndorsement,
      endorsementDate: c.endorsementDate,
      status: c.status,
      notes: c.notes,
      createdAt: c.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      createdBy: c.createdBy,
    );
  }

  Widget _line(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
      ]),
    );
  }

  Widget _img(String url, double w, double h) {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, width: w, height: h, fit: BoxFit.cover);
      } catch (_) {
        return Container(width: w, height: h, color: Colors.grey[200], child: const Icon(Icons.broken_image));
      }
    }
    return Image.network(url, width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  }

  void _fullImage(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: _img(url, double.infinity, 400))));
  }
}
