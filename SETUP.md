# تشغيل نظام إدارة الأصول والعهدة

## المتطلبات
- Flutter SDK (الإصدار المستقر المستخدم في CI).
- مشروع Supabase المرتبط بالتطبيق.
- Android SDK لبناء APK؛ لا يلزم إعداد Firebase.

## إعداد Supabase

المشروع مهيأ افتراضياً على مشروع Supabase المرتبط بالمستودع. عنوان المشروع والمفتاح العام publishable key موجودان كقيم افتراضية عامة داخل خدمة التهيئة، ويمكن تجاوزهما عند البناء:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

لا تضع مفتاح `service_role` في تطبيق Flutter أو GitHub؛ التطبيق يستخدم المفتاح العام فقط، والحماية تعتمد على RLS.

### إعداد أول مدير
1. أنشئ مستخدم المدير في Supabase → Authentication → Users.
2. تحقق من البريد ومعرّف Auth UID.
3. عيّن الدور `primary_admin` لذلك المعرّف في `private.admin_assignments` من SQL Editor بصلاحيات مالك المشروع.
4. لا تستخدم كلمة مرور افتراضية أو تضعها في المستودع.

لا ينشئ التطبيق مديراً تلقائياً ولا يسمح للمستخدم بمنح نفسه صلاحيات مدير. راجع `docs/SUPABASE_DATABASE_ACCESS.md` وملفات `supabase/migrations/`.

## منصات التشغيل والبناء

ملفات Android وWeb موجودة في المستودع:

```bash
flutter pub get
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
flutter build web --release
flutter build apk --release
```

- الويب: `build/web/`
- Android: `build/app/outputs/flutter-apk/app-release.apk`

## قارئ الباركود
- USB: استخدم قارئاً يعمل بوضع Keyboard Wedge، ثم ضع المؤشر في حقل الباركود وامسح الرمز.
- كاميرا الهاتف: اضغط زر مسح الكاميرا بجانب حقل الباركود وامنح إذن الكاميرا.

## التصدير
- تصدير Excel مدعوم.
- تصدير Google Sheets متوقف مؤقتاً إلى أن تتم إضافة تكامل Google OAuth مستقل عن Firebase.

## ملاحظات التسليم
- التطوير يتم على فرع `feature/supabase-admin-handover`.
- لا تدمج PR #2 إلى `main` قبل مراجعة المالك وموافقته.
- لم يتم تنفيذ نقل بيانات أو صلاحيات إلى مدير جديد؛ عملية التسليم تتطلب تحديد حساب الوجهة والتحقق منه أولاً.


## توقيع Android للإنتاج

البناء الآلي الحالي يستخدم توقيع debug إذا لم يُجهّز المالك مفتاح نشر. لتفعيل توقيع الإصدار:

1. أنشئ keystore خاصاً بالمالك على جهاز آمن باستخدام `keytool`، واحتفظ بنسخة احتياطية مشفرة منه.
2. لا ترفع keystore أو كلمات المرور إلى Git ولا ترسلها في المحادثة.
3. أضف القيم التالية في إعدادات المستودع → Settings → Secrets and variables → Actions:
   - `ANDROID_KEYSTORE_BASE64`: محتوى keystore بعد تحويله إلى Base64.
   - `ANDROID_STORE_PASSWORD`: كلمة مرور keystore.
   - `ANDROID_KEY_ALIAS`: اسم المفتاح.
   - `ANDROID_KEY_PASSWORD`: كلمة مرور المفتاح.
4. سيجهز GitHub Actions ملف التوقيع مؤقتاً أثناء البناء، ثم يستخدم توقيع المالك تلقائياً.
5. احتفظ بالمفتاح وكلمات المرور بأمان؛ فقدان مفتاح التوقيع قد يمنع تحديث التطبيق المنشور بنفس هوية الحزمة.

إذا لم تُضف الأسرار، يبقى APK الناتج مخصصاً للاختبار وليس للنشر في المتجر.
