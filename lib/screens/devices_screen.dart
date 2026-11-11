import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _search = '';
  DeviceCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    // فتح نموذج الإضافة إذا طُلب من الشاشة الرئيسية
    if (app.requestOpenAddDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        app.clearOpenAddDevice();
        _showDeviceForm(context, null, app);
      });
    }

    var list = app.devices;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.serialNumber.toLowerCase().contains(q) ||
          d.barcode.toLowerCase().contains(q) ||
          d.model.toLowerCase().contains(q) ||
          d.manufacturer.toLowerCase().contains(q)).toList();
    }
    if (_filterCategory != null) {
      list = list.where((d) => d.category == _filterCategory).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث بالاسم، الرقم التسلسلي، الباركود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // الكل
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    avatar: Icon(Icons.apps_rounded, size: 16, color: _filterCategory == null ? Colors.white : AppTheme.primary),
                    label: const Text('الكل', style: TextStyle(fontSize: 12)),
                    selected: _filterCategory == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filterCategory = null),
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: _filterCategory == null ? Colors.white : null, fontWeight: FontWeight.bold),
                  ),
                ),
                ...DeviceCategory.values.map((c) {
                  final selected = _filterCategory == c;
                  final color = AppIcons.categoryColor(c);
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      avatar: Icon(AppIcons.category(c), size: 16, color: selected ? Colors.white : color),
                      label: Text(c.labelAr, style: TextStyle(fontSize: 11, color: selected ? Colors.white : null)),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filterCategory = c),
                      selectedColor: color,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.devices, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        const Text('لا أجهزة', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final d = list[i];
                      final catColor = AppIcons.categoryColor(d.category);
                      final stColor = AppIcons.statusColor(d.status);
                      final condColor = AppIcons.conditionColor(d.condition);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: SectionIcon(icon: AppIcons.category(d.category), color: catColor, size: 42),
                          title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            '${d.serialNumber}${d.manufacturer.isNotEmpty ? ' • ${d.manufacturer}' : ''}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconChip(icon: AppIcons.deviceStatus(d.status), label: d.status.labelAr, color: stColor, compact: true),
                              const SizedBox(width: 4),
                              Icon(AppIcons.condition(d.condition), size: 16, color: condColor),
                            ],
                          ),
                          onTap: () => _showDeviceDetails(context, d, app),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeviceForm(context, null, app),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showDeviceDetails(BuildContext context, Device d, AppProvider app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${d.category.labelAr} • ${d.manufacturer} ${d.model}'),
                const Divider(height: 28),
                _DetailRow('الرقم التسلسلي', d.serialNumber),
                _DetailRow('الباركود', d.barcode),
                _DetailRow('رقم الأصل', d.assetNumber),
                _DetailRow('الحالة', d.status.labelAr),
                _DetailRow('الحالة الفنية', d.condition.labelAr),
                _DetailRow('الموقع', d.location),
                if (d.assignedEmployee != null) _DetailRow('الموظف', d.assignedEmployee!),
                if (d.cpu != null) _DetailRow('المعالج', d.cpu!),
                if (d.ram != null) _DetailRow('الرام', d.ram!),
                if (d.storage != null) _DetailRow('التخزين', d.storage!),
                if (d.ipAddress != null) _DetailRow('IP', d.ipAddress!),
                if (d.networkConnection != null && d.networkConnection!.isNotEmpty) _DetailRow('مسار الشبكة', d.networkConnection == 'internalServer' ? 'سيرفر داخلي' : d.networkConnection == 'externalInternet' ? 'إنترنت خارجي' : 'غير متصل'),
                if (d.switchNumber != null && d.switchNumber!.isNotEmpty) _DetailRow('رقم السويتش', d.switchNumber!),
                if (d.switchFloor != null && d.switchFloor!.isNotEmpty) _DetailRow('طابق السويتش', d.switchFloor!),
                if (d.switchPortNumber != null && d.switchPortNumber!.isNotEmpty) _DetailRow('منفذ السويتش', d.switchPortNumber!),
                if (d.notes != null && d.notes!.isNotEmpty) _DetailRow('ملاحظات', d.notes!),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeviceForm(context, d, app);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل تريد حذف الجهاز "${d.name}"؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('حذف', style: TextStyle(color: AppTheme.danger)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final msg = await app.deleteDevice(d.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg ?? 'تم الحذف بنجاح')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('حذف'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeviceForm(BuildContext context, Device? existing, AppProvider app) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final manufacturerCtrl = TextEditingController(text: existing?.manufacturer);
    final modelCtrl = TextEditingController(text: existing?.model);
    final serialCtrl = TextEditingController(text: existing?.serialNumber);
    final barcodeCtrl = TextEditingController(text: existing?.barcode);
    final assetCtrl = TextEditingController(text: existing?.assetNumber);
    final locationCtrl = TextEditingController(text: existing?.location);
    final supplierCtrl = TextEditingController(text: existing?.supplier);
    final notesCtrl = TextEditingController(text: existing?.notes);
    final switchNumberCtrl = TextEditingController(text: existing?.switchNumber);
    final switchPortCtrl = TextEditingController(text: existing?.switchPortNumber);
    String networkConnection = existing?.networkConnection ?? '';
    String switchFloor = existing?.switchFloor ?? 'الأرضي';
    DeviceCategory category = existing?.category ?? DeviceCategory.desktop;
    DeviceCondition condition = existing?.condition ?? DeviceCondition.good;
    DeviceStatus status = existing?.status ?? DeviceStatus.inWarehouse;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'إضافة جهاز جديد' : 'تعديل جهاز',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الجهاز *')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeviceCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'التصنيف'),
                    items: DeviceCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.labelAr)))
                        .toList(),
                    onChanged: (v) => setModalState(() => category = v!),
                  ),
                  const SizedBox(height: 10),
                  _SuggestField(
                    controller: manufacturerCtrl,
                    label: 'الشركة المصنعة',
                    icon: Icons.business_rounded,
                    suggestions: app.catalog.suggestManufacturers,
                  ),
                  const SizedBox(height: 10),
                  _SuggestField(
                    controller: modelCtrl,
                    label: 'الطراز / الموديل',
                    icon: Icons.memory_rounded,
                    hint: 'يُحفظ تلقائياً في القائمة بعد أول إدخال',
                    suggestions: app.catalog.suggestModels,
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'الرقم التسلسلي *')),
                  const SizedBox(height: 10),
                  TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'الباركود / QR')),
                  const SizedBox(height: 10),
                  TextField(controller: assetCtrl, decoration: const InputDecoration(labelText: 'رقم الأصل / العهدة')),
                  const SizedBox(height: 10),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'الموقع')),
                  if (category == DeviceCategory.desktop || category == DeviceCategory.laptop) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('بيانات اتصال الشبكة', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: networkConnection.isEmpty ? null : networkConnection,
                      decoration: const InputDecoration(labelText: 'يتصل الحاسب بـ'),
                      items: const [
                        DropdownMenuItem(value: 'internalServer', child: Text('سيرفر داخلي')),
                        DropdownMenuItem(value: 'externalInternet', child: Text('إنترنت خارجي')),
                        DropdownMenuItem(value: 'none', child: Text('غير متصل بالشبكة')),
                      ],
                      onChanged: (v) => setModalState(() => networkConnection = v ?? ''),
                    ),
                    if (networkConnection == 'internalServer' || networkConnection == 'externalInternet') ...[
                      TextField(controller: switchNumberCtrl, decoration: const InputDecoration(labelText: 'رقم السويتش')),
                      DropdownButtonFormField<String>(
                        value: switchFloor,
                        decoration: const InputDecoration(labelText: 'طابق السويتش'),
                        items: const ['القبو', 'الأرضي', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر'].map((floor) => DropdownMenuItem(value: floor, child: Text(floor))).toList(),
                        onChanged: (v) => setModalState(() => switchFloor = v ?? 'الأرضي'),
                      ),
                      TextField(controller: switchPortCtrl, decoration: const InputDecoration(labelText: 'رقم منفذ السويتش')),
                    ],
                  ],
                  const SizedBox(height: 10),
                  TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'المورد')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeviceStatus>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'حالة التواجد'),
                    items: DeviceStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.labelAr)))
                        .toList(),
                    onChanged: (v) => setModalState(() => status = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeviceCondition>(
                    value: condition,
                    decoration: const InputDecoration(labelText: 'الحالة الفنية'),
                    items: DeviceCondition.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.labelAr)))
                        .toList(),
                    onChanged: (v) => setModalState(() => condition = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات'), maxLines: 2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || serialCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الاسم والرقم التسلسلي مطلوبان')),
                        );
                        return;
                      }
                      final now = DateTime.now().toIso8601String();
                      final device = Device(
                        id: existing?.id ?? const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        category: category,
                        manufacturer: manufacturerCtrl.text.trim(),
                        model: modelCtrl.text.trim(),
                        serialNumber: serialCtrl.text.trim(),
                        barcode: barcodeCtrl.text.trim(),
                        assetNumber: assetCtrl.text.trim(),
                        purchaseDate: existing?.purchaseDate ?? now.split('T').first,
                        supplier: supplierCtrl.text.trim(),
                        condition: condition,
                        status: status,
                        location: locationCtrl.text.trim(),
                        networkConnection: (category == DeviceCategory.desktop || category == DeviceCategory.laptop) ? networkConnection : existing?.networkConnection,
                        switchNumber: (category == DeviceCategory.desktop || category == DeviceCategory.laptop) ? switchNumberCtrl.text.trim() : existing?.switchNumber,
                        switchFloor: (category == DeviceCategory.desktop || category == DeviceCategory.laptop) ? switchFloor : existing?.switchFloor,
                        switchPortNumber: (category == DeviceCategory.desktop || category == DeviceCategory.laptop) ? switchPortCtrl.text.trim() : existing?.switchPortNumber,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        attachments: existing?.attachments ?? [],
                        createdAt: existing?.createdAt ?? now,
                        updatedAt: now,
                        cpu: existing?.cpu,
                        ram: existing?.ram,
                        storage: existing?.storage,
                        assignedEmployee: existing?.assignedEmployee,
                      );
                      final msg = await app.saveDevice(device);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg ?? 'تم الحفظ بنجاح')),
                        );
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}


/// حقل إدخال مع اقتراحات من الكتالوج (موديل / شركة)
class _SuggestField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final List<String> Function(String query) suggestions;

  const _SuggestField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suggestions,
    this.hint,
  });

  @override
  State<_SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<_SuggestField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (TextEditingValue tev) {
        final list = widget.suggestions(tev.text);
        return list;
      },
      onSelected: (v) {
        widget.controller.text = v;
        widget.controller.selection = TextSelection.collapsed(offset: v.length);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, size: 20),
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList();
        if (opts.isEmpty) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (_, i) {
                  final o = opts[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history_rounded, size: 16, color: AppTheme.textSecondary),
                    title: Text(o, style: const TextStyle(fontSize: 13)),
                    onTap: () => onSelected(o),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String get labelText => widget.label;
}
