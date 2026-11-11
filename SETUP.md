# تجهيز المشروع للتشغيل — دائرة الاتصالات

## الحالة الحالية

هذا المستودع يحتاج إعداد Firebase خاصاً بمالك المشروع قبل التشغيل. لا تضع مفاتيح الخدمة الخاصة أو مفاتيح Admin SDK داخل التطبيق أو GitHub. ملف `lib/firebase_options.dart` يُولّد محلياً بواسطة FlutterFire CLI ولا ينبغي استبداله بقيم تخمينية.

## دليل المدير

لخطوات Firebase التفصيلية من منظور مدير النظام، راجع [دليل مدير النظام لربط Firebase](docs/FIREBASE_ADMIN_BOOTSTRAP_AR.md).

## تسليم إدارة النظام ونقل البيانات

راجع [دليل تسليم إدارة النظام وترحيل الملكية](docs/ADMIN_HANDOVER_AND_MIGRATION_AR.md) لمعرفة آلية تعيين مدير جديد بموافقة المدير الحالي، والتحقق من الحساب، ونقل صلاحيات الإدارة، وحماية البيانات وسجل التدقيق. هذه المواصفات لا تعني أن النقل نُفّذ أو أن Cloud Functions قد نُشرت؛ يلزم تنفيذ المراحل واختبارها قبل الإنتاج.

## 1. المتطلبات

- Flutter SDK متوافق مع قيود `pubspec.yaml`
- Firebase project مع Authentication وCloud Firestore
- FlutterFire CLI
- Firebase CLI لتوزيع قواعد Firestore

## 2. إعداد Firebase

من مجلد المشروع:

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
```

اختر مشروع Firebase الصحيح والمنصات المطلوبة (Android وWeb، ثم iOS). احتفظ بملف `lib/firebase_options.dart` الناتج محلياً، وأضف ملفات المنصات المطلوبة وفق تعليمات FlutterFire.

فعّل Google Sign-In من Firebase Authentication، وأضف بصمات SHA-1/SHA-256 لتطبيق Android عند الحاجة.

## 3. تهيئة مدير النظام

قبل تسجيل الدخول الأول، أنشئ يدوياً من Firebase Console وثيقة:

- Collection: `system_settings`
- Document: `telecom`

الحقول:

```json
{
  "adminEmails": ["ضع-بريد-المدير-المعتمد-هنا"],
  "departmentName": "دائرة الاتصالات",
  "updatedAt": "2026-11-11T00:00:00Z"
}
```

استبدل البريد التجريبي بالبريد أو عناوين البريد المعتمدة فعلياً. لا تمنح أي مستخدم صفة مدير لمجرد أنه يستطيع تعديل إعدادات محلية على جهازه. لا تسمح قواعد Firestore بتعديل قائمة المديرين إلا لمدير موجود مسبقاً في الوثيقة.

**تم ربط العميل الآن:** يقرأ `FirebaseService` قائمة `adminEmails` من `system_settings/telecom`، ويستخدمها لتحديد صلاحية رئيس الدائرة/مدير النظام. كما أصبحت قائمة طلبات الاعتماد تُقرأ كاملة للمدير فقط، بينما يقتصر استعلام المستخدم العادي على طلباته بواسطة `requesterUid`. يتطلب ذلك تسجيل الخروج والدخول بعد تعديل قائمة المديرين من Firebase Console حتى يعاد تحميلها.

## 4. نشر قواعد Firestore

ثبّت Firebase CLI وسجّل الدخول، ثم من جذر المشروع:

```bash
firebase use <FIREBASE_PROJECT_ID>
firebase deploy --only firestore:rules
```

لا تنشر قبل مراجعة المشروع والوثيقة الابتدائية. اختبر القواعد بحساب مدير وحساب مستخدم عادي باستخدام Firebase Emulator أو Rules Playground.

## 5. تسليم إدارة النظام عبر Cloud Functions

أضيفت واجهة أولية لتسليم الإدارة إلى حساب موجود وموثق في Firebase Authentication. عند البقاء في مشروع Firebase نفسه، لا تُنسخ بيانات القسم؛ تبقى وثائق Firestore والملفات وحسابات المستخدمين في مكانها، ويُغيّر النظام معرّف المدير المعتمد.

المتطلبات:
- مشروع Firebase يدعم نشر Cloud Functions (قد يتطلب تفعيل خطة الفوترة Blaze وفق متطلبات Firebase الحالية).
- Node.js 22 وFirebase CLI.
- المدير الجديد أنشأ حساباً وسجّل الدخول مرة واحدة على الأقل ووثّق بريده.
- نشر قواعد Firestore وCloud Functions من مالك المشروع أو شخص مخوّل.

من جذر المشروع:

```bash
firebase use YOUR_FIREBASE_PROJECT_ID
cd functions
npm install
npm run lint
cd ..
firebase deploy --only firestore:rules,functions
```

سير العمل في التطبيق:
1. المدير الحالي يفتح «تسليم / استلام الإدارة» ويُدخل بريد الحساب الجديد.
2. ينسخ معرّف الطلب ويرسله للمدير الجديد عبر قناة موثوقة.
3. المدير الجديد يسجل الدخول بحسابه، ويفتح الشاشة نفسها، ويدخل المعرّف ثم يضغط «قبول استلام الإدارة».
4. يعود المدير الحالي إلى حسابه، ويدخل معرّف العملية، ثم يضغط «اعتماد التسليم النهائي» ويعيد المصادقة بحساب Google.
5. بعد نجاح العملية، يسجل المدير الجديد الخروج والدخول مجدداً لتحديث صلاحياته المحلية.

ملاحظات أمان وتشغيل:
- لا ترسل Service Account JSON أو مفاتيح Admin SDK إلى التطبيق أو GitHub.
- تغييرات المدير تُنفذ من Cloud Functions باستخدام Admin SDK؛ قواعد Firestore تمنع العميل من تعديل وثيقة الإدارة وسجلات التسليم مباشرة.
- يعتمد التفويض بعد أول تسليم على `currentAdminUid` في وثيقة `system_settings/telecom`. قبل ذلك يمكن استخدام قائمة `adminEmails` للتهيئة الأولى فقط.
- إزالة صلاحية المدير السابق تخص إدارة التطبيق، ولا تحذف حساب Firebase Authentication ولا تنقل ملكية مشروع Google Cloud أو الفوترة.
- إذا تعطلت عملية بعد إنشاء طلب وقبل اكتمالها، لا تعدّل وثائق الإدارة يدوياً عشوائياً؛ راجع سجلات Cloud Functions ووثيقة الطلب قبل الاستعادة.
- هذه النسخة تنفذ نقل الإدارة داخل مشروع Firebase نفسه. لا تنفذ ترحيلاً بين مشروعين ولا تنقل ملكية ملفات Google Drive/Sheets.
- يجب اختبار العملية في مشروع تجريبي قبل نشرها على بيانات فعلية.

## 5. Google Sheets

- فعّل Google Sheets API في Google Cloud.
- اضبط OAuth consent screen والنطاق `https://www.googleapis.com/auth/spreadsheets`.
- أضف مستخدمي الاختبار عند وضع التطبيق في Testing.
- اضبط OAuth clients لكل منصة واختبر طلب الصلاحية وتصدير جدول فعلي.

## 6. Supabase (اختياري وغير معتمد للإنتاج حالياً)

المسار البديل في التطبيق يحتاج مراجعة منفصلة لسياسات RLS وصلاحيات المدير؛ لا تستخدم مفتاح `service_role` في التطبيق. لا تعتبر مسار Supabase جاهزاً للإنتاج قبل اختبار جميع الجداول وسياسات القراءة والكتابة والاعتماد.

## 7. فحوصات البناء

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

بعد إعداد Mac/Xcode وملفات توقيع iOS:

```bash
flutter build ipa --release
```

لا تُعلن جاهزية أي منصة إلا بعد نجاح البناء واختبار تسجيل الدخول والقراءة والكتابة والصلاحيات على جهاز أو متصفح فعلي.
