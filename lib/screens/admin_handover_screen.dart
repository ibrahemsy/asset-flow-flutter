import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AdminHandoverScreen extends StatefulWidget {
  const AdminHandoverScreen({super.key});

  @override
  State<AdminHandoverScreen> createState() => _AdminHandoverScreenState();
}

class _AdminHandoverScreenState extends State<AdminHandoverScreen> {
  final _emailController = TextEditingController();
  final _operationController = TextEditingController();
  bool _busy = false;
  String? _message;
  String? _operationId;

  @override
  void dispose() {
    _emailController.dispose();
    _operationController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _message = 'تعذر تنفيذ العملية: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(AppProvider app) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'أدخل بريد المدير الجديد.');
      return;
    }
    await _run(() async {
      final id = await app.createAdminHandover(email);
      if (!mounted) return;
      setState(() {
        _operationId = id;
        _operationController.text = id;
        _message = 'تم إنشاء طلب التسليم. أرسل معرّف الطلب للمدير الجديد ليقبله بعد تسجيل الدخول.';
      });
    });
  }

  Future<void> _accept(AppProvider app) async {
    final id = _operationController.text.trim();
    if (id.isEmpty) {
      setState(() => _message = 'أدخل معرّف طلب التسليم الذي وصلك.');
      return;
    }
    await _run(() async {
      await app.acceptAdminHandover(id);
      if (mounted) setState(() => _message = 'تم قبول طلب استلام الإدارة. ينتظر موافقة المدير الحالي.');
    });
  }

  Future<void> _findInvitation(AppProvider app) async {
    await _run(() async {
      final invitation = await app.findMyAdminHandoverInvitation();
      final id = invitation['operationId'] as String;
      if (!mounted) return;
      setState(() {
        _operationId = id;
        _operationController.text = id;
        _message = 'تم العثور على دعوة من ${invitation['fromAdminEmail'] ?? 'المدير الحالي'}، ويمكنك الآن قبول استلام الإدارة.';
      });
    });
  }

  Future<void> _approve(AppProvider app) async {
    final id = _operationController.text.trim();
    if (id.isEmpty) {
      setState(() => _message = 'أدخل معرّف طلب التسليم.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسليم الإدارة'),
        content: const Text(
          'بعد نجاح العملية ستنتقل صلاحيات المدير إلى الحساب الجديد، وستُلغى صلاحيات حسابك الحالي. لا يمكن التراجع من هذه الشاشة.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد التسليم')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await app.reauthenticateCurrentUser();
      await app.approveAdminHandover(id);
      if (mounted) setState(() => _message = 'اكتمل التسليم. لم يعد حسابك الحالي يملك صلاحيات المدير.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isCurrentAdmin = app.isHeadOfDept;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined),
                      SizedBox(width: 8),
                      Text('تسليم إدارة النظام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يجب أن يكون المدير الجديد قد أنشأ حساباً في التطبيق ووثّق بريده الإلكتروني. تبقى بيانات القسم في مشروع Firebase نفسه؛ لا تُنسخ أو تُحذف أثناء تغيير المدير.',
                  ),
                  const SizedBox(height: 16),
                  if (isCurrentAdmin) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'بريد المدير الجديد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _create(app),
                        icon: const Icon(Icons.send),
                        label: const Text('إنشاء طلب تسليم'),
                      ),
                    ),
                  ] else
                    const Text('يمكنك قبول دعوة تسليم موجهة إلى بريد حسابك بعد تسجيل الدخول وتوثيق البريد.'),
                  const Divider(height: 28),
                  TextField(
                    controller: _operationController,
                    decoration: const InputDecoration(
                      labelText: 'معرّف طلب التسليم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isCurrentAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _findInvitation(app),
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('البحث عن دعوة موجهة إلى بريدي'),
                      ),
                    ),
                  if (!isCurrentAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _accept(app),
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text('قبول استلام الإدارة'),
                      ),
                    ),
                  if (isCurrentAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : () => _approve(app),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('اعتماد التسليم النهائي'),
                      ),
                    ),
                  if (isCurrentAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                                final id = _operationController.text.trim();
                                if (id.isEmpty) {
                                  setState(() => _message = 'أدخل معرّف طلب التسليم أولاً.');
                                  return;
                                }
                                _run(() async {
                                  await app.cancelAdminHandover(id);
                                  if (mounted) {
                                    setState(() => _message = 'تم إلغاء طلب التسليم.');
                                  }
                                });
                              },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('إلغاء طلب التسليم'),
                      ),
                    ),
                  if (_busy) const LinearProgressIndicator(),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(_message!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  if (_operationId != null) ...[
                    const SizedBox(height: 8),
                    SelectableText('معرّف العملية: $_operationId'),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: _operationId!));
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('تم نسخ معرّف طلب التسليم')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('نسخ معرّف الطلب لمشاركته مع المدير الجديد'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
