# تجهيز المشروع للتشغيل — دائرة الاتصالات

## الحالة الحالية

هذا المستودع يحتاج إعداد Firebase خاصاً بمالك المشروع قبل التشغيل. لا تضع مفاتيح الخدمة الخاصة أو مفاتيح Admin SDK داخل التطبيق أو GitHub. ملف `lib/firebase_options.dart` يُولّد محلياً بواسطة FlutterFire CLI ولا ينبغي استبداله بقيم تخمينية.

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
