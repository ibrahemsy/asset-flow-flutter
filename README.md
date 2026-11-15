# نظام إدارة الأصول والعهدة — دائرة الاتصالات

تطبيق Flutter لإدارة الأصول والأجهزة، بطاقات العهدة، الحركات، الصيانة، شبكات الاتصالات، التقارير، والاستيراد والتصدير عبر Excel.

## الخلفية والصلاحيات

- Supabase هو مزود الخلفية الوحيد: Auth وPostgres.
- لا يعتمد التطبيق على Firebase أو Firestore.
- يستخدم التطبيق مفتاح Supabase العام (publishable/anon) فقط.
- حماية البيانات مفروضة من قاعدة البيانات عبر Row Level Security (RLS) والأدوار المخزنة في `private.admin_assignments`.
- لا تضع مفتاح `service_role` أو كلمات المرور في التطبيق أو المستودع.

## التشغيل محلياً

يتطلب Flutter SDK وAndroid SDK لبناء Android:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

راجع [SETUP.md](SETUP.md) وخطط الترحيل داخل `supabase/migrations/` قبل ربط مشروع Supabase آخر.

## بناء النسختين

```bash
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
flutter build web --release
flutter build apk --release
```

- ملفات الويب: `build/web/`
- ملف Android APK: `build/app/outputs/flutter-apk/app-release.apk`

## الباركود

- قارئ USB الذي يعمل بوضع Keyboard Wedge: ضع المؤشر داخل حقل الباركود ثم امسح الرمز.
- كاميرا الهاتف: استخدم زر مسح الكاميرا واسمح بالوصول إلى الكاميرا.

## التصدير

- استيراد وتصدير Excel مدعومان.
- تصدير Google Sheets غير مفعل حالياً؛ يحتاج تكامل Google OAuth مستقل.

## المدير وتسليم الإدارة

- الدور الإداري يُقرأ من قاعدة البيانات، ولا يُستنتج من البريد أو بيانات الجهاز.
- إعداد المدير الأول يتم بعد إنشاء مستخدم Auth ومنحه الدور من مسار إداري موثوق.
- بنية تسليم الإدارة وتوثيق النقل موجودة في مخطط قاعدة البيانات، لكن نقل المشروع والجداول والبيانات وملفات Storage وAuth إلى مشروع مدير جديد لم يُنفذ بعد.
- لا يُدمج PR #2 إلى `main` دون موافقة مالك المستودع.

التطوير الحالي على الفرع `feature/supabase-admin-handover`.
