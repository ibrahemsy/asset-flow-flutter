import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/app_icons.dart';

/// دليل الاستخدام الكامل + قاموس المصطلحات
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 22),
              SizedBox(width: 8),
              Text('دليل الاستخدام'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _intro(),
            const SizedBox(height: 16),
            _sectionTitle(Icons.playlist_add_check_rounded, 'كيف تبدأ؟'),
            _stepCard(1, 'تسجيل الدخول', 'ادخل بحساب Google التابع للوزارة. رئيس دائرة الاتصالات يُعتبر مدير النظام تلقائياً.'),
            _stepCard(2, 'استكشف اللوحة', 'من الرئيسية ترى أعداد الأجهزة والعهدة والبلاغات. اضغط أي بطاقة للانتقال السريع.'),
            _stepCard(3, 'القائمة الجانبية', 'اسحب من اليمين أو زر القائمة للوصول لكل الأقسام: أجهزة، عهدة، حركات، شبكة، صيانة، تقارير...'),

            const SizedBox(height: 20),
            _sectionTitle(Icons.devices_other_rounded, 'إضافة جهاز / قطعة'),
            _howTo(
              title: 'خطوات إضافة جهاز جديد',
              steps: [
                'من الشريط السفلي أو القائمة اختر «الأجهزة».',
                'اضغط زر + في الأسفل.',
                'أدخل اسم الجهاز (مثال: حاسب مكتب المدير).',
                'اختر التصنيف (حاسب مكتبي، سويتش، طابعة...).',
                'اكتب الشركة المصنعة — ستظهر اقتراحات من الأجهزة السابقة.',
                'اكتب الموديل — أي موديل جديد يُحفظ تلقائياً ويظهر لاحقاً في القائمة.',
                'أدخل الرقم التسلسلي ورقم العهدة/المالي إن وُجد.',
                'حدد الموقع وحالة التواجد والحالة الفنية.',
                'اضغط «حفظ».',
                'إن كنت فنياً: يُرسل الطلب لمدير النظام للاعتماد. إن كنت رئيساً: يُحفظ مباشرة.',
              ],
            ),
            _tip('الموديل والشركة: عند إدخال موديل لأول مرة يُضاف للكتالوج المحلي. في المرة التالية يظهر كخيار عند الكتابة في حقل الموديل.'),

            const SizedBox(height: 16),
            _sectionTitle(Icons.badge_rounded, 'بطاقة العهدة'),
            _howTo(
              title: 'إنشاء بطاقة عهدة لموظف',
              steps: [
                'افتح «العهدة» من الشريط أو القائمة.',
                'اضغط + وأدخل: رقم البطاقة، اسم الموظف، الرقم الوطني (الهوية).',
                'أكمل الوظيفة والدائرة والشعبة ثم احفظ.',
                'افتح البطاقة واضغط «مادة» لإضافة كل قطعة استلمها الموظف.',
                'يمكن رفع صورة لكل مادة من أيقونة الكاميرا.',
                'للبحث: استخدم وضع «الهوية» برقم وطني لمعرفة ماذا استلم الشخص، أو «المادة» بالاسم/السيريال.',
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitle(Icons.swap_horiz_rounded, 'الحركات والصيانة'),
            _howTo(
              title: 'سند حركة (تسليم / إعادة / نقل)',
              steps: [
                'من القائمة: الحركات → +.',
                'اختر نوع الحركة والجهاز من القائمة.',
                'حدد من وإلى والسبب ورقم السند ثم احفظ.',
              ],
            ),
            _howTo(
              title: 'بلاغ صيانة',
              steps: [
                'الصيانة → +.',
                'رقم البلاغ، اسم الجهاز، وصف العطل، الأولوية، الفني المكلف.',
                'تتبع الحالة من جديد → قيد المعالجة → تم الإصلاح → مغلق.',
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitle(Icons.hub_rounded, 'الشبكة والتقارير'),
            _paragraph(
              'شاشة الشبكة ترسم الطبقات: إنترنت → ألياف → سيرفرات → سويتشات → مقاسم هاتفية. '
              'التقارير تتيح تصدير Excel واستيراد ملفات وربط Google Sheets.',
            ),

            const SizedBox(height: 16),
            _sectionTitle(Icons.verified_user_rounded, 'الأدوار والصلاحيات'),
            _roleCard(
              'مدير النظام (رئيس دائرة الاتصالات)',
              'كتابة مباشرة، اعتماد/رفض طلبات الفنيين، إعداد Firebase/Supabase، إدارة قائمة المديرين.',
              AppTheme.success,
            ),
            _roleCard(
              'فني / موظف',
              'إدخال البيانات كطلبات اعتماد. لا تُطبَّق التعديلات إلا بعد موافقة المدير.',
              AppTheme.primary,
            ),

            const SizedBox(height: 24),
            _sectionTitle(Icons.menu_book_rounded, 'قاموس المصطلحات'),
            ..._glossary.map((g) => _term(g.$1, g.$2)),

            const SizedBox(height: 24),
            _sectionTitle(Icons.lightbulb_rounded, 'نصائح سريعة'),
            _tip('ابحث بالهوية في العهدة لمعرفة كل ما استلمه موظف.'),
            _tip('استخدم فلتر التصنيف في الأجهزة بأيقونات بدل قراءة النص الطويل.'),
            _tip('صدّر تقرير شامل من شاشة التقارير قبل الجرد السنوي.'),
            _tip('ارفع صوراً للمواد ذات القيمة العالية لتوثيق الحالة عند التسليم.'),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نظام إدارة الأصول والعهدة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'دليل مختصر لموظفي دائرة الاتصالات — وزارة الطوارئ وإدارة الكوارث. '
            'يغطي إضافة الأجهزة والموديلات، العهدة، الحركات، الصيانة، والبحث.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _stepCard(int n, String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Text('$n', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(body, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _howTo({required String title, required List<String> steps}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12, height: 1.35))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textPrimary)),
    );
  }

  Widget _roleCard(String title, String body, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SectionIcon(icon: Icons.shield_rounded, color: color, size: 40),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        subtitle: Text(body, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _term(String term, String meaning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(term, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
            const SizedBox(height: 4),
            Text(meaning, style: const TextStyle(fontSize: 12, height: 1.35, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35))),
        ],
      ),
    );
  }

  static const List<(String, String)> _glossary = [
    ('عهدة', 'المواد أو الأجهزة المسلّمة رسمياً لموظف ويتحمّل مسؤوليتها حتى الإعادة أو النقل.'),
    ('بطاقة عهدة', 'وثيقة تسجّل اسم الموظف ورقم هويته وقائمة المواد التي استلمها مع التواريخ والتواقيع.'),
    ('الرقم الوطني / الهوية', 'رقم هوية الموظف؛ يُستخدم للبحث ومعرفة كل ما استلمه عبر البطاقات المرتبطة به.'),
    ('الرقم التسلسلي (SN)', 'رقم فريد يضعه المصنّع على الجهاز؛ أساسي للتتبع والجرد.'),
    ('الباركود / QR', 'رمز قابل للمسح السريع لربط الجهاز بسجل النظام دون كتابة الرقم يدوياً.'),
    ('رقم الأصل / المالي', 'الرقم المحاسبي أو الإداري للعهدة في سجلات الوزارة.'),
    ('الموديل', 'طراز الجهاز (مثل OptiPlex 7090). يُحفظ تلقائياً في قائمة الاقتراحات بعد أول إدخال.'),
    ('الشركة المصنعة', 'العلامة التجارية (HP، Dell، Cisco...). تظهر كاقتراحات عند الكتابة.'),
    ('التصنيف', 'نوع التجهيز: حاسب مكتبي، محمول، سويتش، راوتر، طابعة، ألياف، هاتف...'),
    ('حالة التواجد', 'أين الجهاز الآن: مستودع، مسلّم لموظف، مسلّم لقسم، قيد الصيانة، خارج الخدمة.'),
    ('الحالة الفنية', 'جودة الجهاز: ممتازة، جيدة، تحتاج صيانة، معطلة، خارج الخدمة.'),
    ('سند حركة', 'وثيقة تسجيل تسليم أو إعادة أو نقل أو استبدال جهاز بين جهتين.'),
    ('بلاغ صيانة', 'طلب إصلاح عطل مع أولوية وحالة (جديد، قيد المعالجة، بانتظار قطع، مصلحة، مغلق).'),
    ('مدير النظام', 'رئيس دائرة الاتصالات؛ يعتمد الطلبات ويكتب مباشرة ويدير الإعدادات (Firebase/Supabase).'),
    ('فني', 'موظف يدخل البيانات كطلبات؛ لا تُنفَّذ إلا بعد اعتماد المدير.'),
    ('طلب اعتماد', 'تعديل يقترحه فني وينتظر موافقة أو رفض مدير النظام.'),
    ('المقسم (PBX)', 'جهاز توزيع الهواتف الداخلية؛ كل رقم يرتبط بمنفذ على المقسم.'),
    ('سويتش', 'محول شبكة يربط أجهزة المكاتب؛ له منافذ تُربط بنقاط الحائط.'),
    ('ألياف ضوئية', 'كابلات نقل بيانات عالية السرعة بين المواقع أو مع مزود الإنترنت.'),
    ('Firestore / Supabase', 'قواعد بيانات سحابية يخزّن فيها النظام الأجهزة والعهدة والطلبات.'),
  ];
}
