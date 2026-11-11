# تجهيز المشروع للتشغيل — دائرة الاتصالات

## 1) المتطلبات
- Flutter SDK 3.16+
- حساب Google Cloud / Firebase
- (اختياري) مشروع Supabase

```bash
cd asset_flow_flutter
flutter pub get
```

---

## 2) Firebase (إلزامي للوضع الافتراضي)

### أ. إنشاء المشروع
1. افتح [Firebase Console](https://console.firebase.google.com)
2. مشروع جديد (مثلاً `asset-flow-telecom`)
3. أضف تطبيق **Android** / **iOS** / **Web** حسب الحاجة

### ب. Authentication
- Authentication → Sign-in method → فعّل **Google**
- أضف البريد التجريبي إن لزم

### ج. Firestore
- أنشئ قاعدة Firestore (وضع production أو test مؤقتاً)
- هيكل مقترح (ينشئه التطبيق تلقائياً):
  - `department_data/telecom/devices`
  - `custody_cards` / `movements` / `maintenance_tickets` / …
  - `pending_requests` / `audit_logs` / `system_settings`

### د. إعداد FlutterFire
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
يستبدل `lib/firebase_options.dart` بالقيم الحقيقية.

### هـ. Android — Google Sign-In
- من Firebase: نزّل `google-services.json` → `android/app/`
- SHA-1 للتطوير:
```bash
cd android && ./gradlew signingReport
```
أضف SHA-1 في إعدادات تطبيق Android في Firebase.

### و. قواعد Firestore (مثال مبدئي)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
لاحقاً قيّد الكتابة حسب الدور (مدير النظام).

---

## 3) Google Sheets (مهم)

التطبيق يطلب صلاحية:
`https://www.googleapis.com/auth/spreadsheets`

### أ. Google Cloud Console
1. نفس مشروع Firebase أو مشروع مرتبط
2. **APIs & Services → Enable APIs** → فعّل **Google Sheets API**
3. **OAuth consent screen**:
   - نوع External أو Internal (Workspace)
   - أضف نطاق: `.../auth/spreadsheets` و `email` و `profile`
   - أضف مستخدمين تجريبيين أثناء التطوير
4. **Credentials**: OAuth 2.0 Client (Android/iOS/Web) متوافق مع Firebase

### ب. من داخل التطبيق
1. سجّل الدخول بـ **Google** (من شاشة الدخول)
2. عند أول تصدير لـ Sheets قد يُطلب الموافقة على الصلاحية
3. التقارير → **تصدير الجرد إلى Google Sheets** أو **تقرير شامل**
4. يُنشأ جدول جديد في حسابك ويُفتح الرابط

### ج. استكشاف الأخطاء
| المشكلة | الحل |
|---------|------|
| فشل إنشاء الجدول | تأكد من تفعيل Sheets API |
| لا يوجد access token | اخرج وادخل من جديد واقبل صلاحية Sheets |
| 403 | أضف الحساب كمستخدم تجريبي في OAuth consent |
| Android | تحقق SHA-1 و `google-services.json` |

---

## 4) Supabase (اختياري)
1. أنشئ مشروعاً على supabase.com
2. نفّذ ملف `supabase_schema.sql` من SQL Editor
3. من التطبيق (مدير النظام فقط): الإدارة → اختر Supabase → الصق URL و Anon Key → حفظ
4. أعد تشغيل التطبيق

---

## 5) مدير النظام
البريد الافتراضي لرئيس دائرة الاتصالات / مدير النظام:
- `ferasnatof@gmail.com`
- `gfa437926@gmail.com`

يمكن إضافة بريد آخر من شاشة **الإدارة**.

---

## 6) التشغيل
```bash
flutter run
# أو
flutter build apk
flutter build web
```

---

## 7) مسار الاستخدام اليومي
1. دخول Google
2. إضافة أجهزة (الموديل يُحفظ للاقتراحات)
3. بطاقات عهدة + رقم وطني + صور
4. الفنيون يرسلون طلبات → المدير يعتمد
5. التقارير → Excel أو Google Sheets للجرد
'''
Path('/home/workdir/artifacts/asset_flow_flutter/SETUP.md').write_text(open('/home/workdir/artifacts/asset_flow_flutter/SETUP.md').read() if False else '''# تجهيز المشروع للتشغيل — دائرة الاتصالات

## 1) المتطلبات
- Flutter SDK 3.16+
- حساب Google Cloud / Firebase
- (اختياري) مشروع Supabase

```bash
cd asset_flow_flutter
flutter pub get
```

---

## 2) Firebase (إلزامي للوضع الافتراضي)

### أ. إنشاء المشروع
1. افتح [Firebase Console](https://console.firebase.google.com)
2. مشروع جديد (مثلاً `asset-flow-telecom`)
3. أضف تطبيق **Android** / **iOS** / **Web** حسب الحاجة

### ب. Authentication
- Authentication → Sign-in method → فعّل **Google**

### ج. Firestore
- أنشئ قاعدة Firestore
- المجموعات تُنشأ تلقائياً عند أول حفظ

### د. إعداد FlutterFire
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
يستبدل `lib/firebase_options.dart` بالقيم الحقيقية.

### هـ. Android — Google Sign-In
- نزّل `google-services.json` → `android/app/`
```bash
cd android && ./gradlew signingReport
```
أضف SHA-1 في Firebase.

### و. قواعد Firestore (تطوير)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 3) Google Sheets

الصلاحية المستخدمة: `https://www.googleapis.com/auth/spreadsheets`

### Google Cloud
1. فعّل **Google Sheets API**
2. شاشة موافقة OAuth + نطاق spreadsheets
3. أضف مستخدمين تجريبيين أثناء التطوير

### من التطبيق
1. دخول بحساب Google
2. التقارير → «تصدير الجرد إلى Google Sheets» أو «تقرير شامل»
3. يُنشأ جدول جديد ويظهر زر «فتح الجدول»

| مشكلة | حل |
|--------|-----|
| فشل الإنشاء | تفعيل Sheets API |
| لا token | إعادة الدخول وقبول الصلاحية |
| 403 | مستخدم تجريبي في OAuth |
| Android | SHA-1 + google-services.json |

---

## 4) Supabase (اختياري)
1. نفّذ `supabase_schema.sql`
2. الإدارة → Supabase → URL + Anon Key → حفظ → أعد التشغيل

---

## 5) مدير النظام
- `ferasnatof@gmail.com`
- `gfa437926@gmail.com`
(قابل للإضافة من شاشة الإدارة)

---

## 6) التشغيل
```bash
flutter run
flutter build apk
```
''')
print('SETUP written')
PY
# fix - the write was messy, write cleanly
cat > /home/workdir/artifacts/asset_flow_flutter/SETUP.md << 'EOF'
# تجهيز المشروع للتشغيل — دائرة الاتصالات

## 1) المتطلبات
- Flutter SDK 3.16+
- حساب Google Cloud / Firebase
- (اختياري) مشروع Supabase

```bash
cd asset_flow_flutter
flutter pub get
```

---

## 2) Firebase (الوضع الافتراضي)

1. أنشئ مشروعاً في [Firebase Console](https://console.firebase.google.com)
2. Authentication → فعّل **Google**
3. أنشئ **Firestore Database**
4. اربط Flutter:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
5. Android: ضع `google-services.json` في `android/app/` وأضف **SHA-1**:
```bash
cd android && ./gradlew signingReport
```

قواعد تطوير مؤقتة:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 3) Google Sheets (مهم)

الصلاحية: `https://www.googleapis.com/auth/spreadsheets`

### في Google Cloud (نفس مشروع Firebase غالباً)
1. **Enable API** → Google Sheets API
2. **OAuth consent screen** → أضف النطاق أعلاه + email/profile
3. أضف حسابات تجريبية أثناء التطوير
4. تأكد من OAuth Client متوافق مع منصة التشغيل (Android/iOS/Web)

### في التطبيق
1. سجّل الدخول بـ Google من شاشة الدخول
2. افتح **التقارير**
3. اختر:
   - **تصدير الجرد إلى Google Sheets** (أجهزة + عهدة)
   - **تقرير شامل على Google Sheets** (أجهزة + عهدة + حركات + صيانة)
4. بعد النجاح: زر **فتح الجدول** في المتصفح

### أعطال شائعة
| المشكلة | الحل |
|---------|------|
| فشل إنشاء الجدول | تفعيل Sheets API |
| لا يوجد access token | خروج ودخول وقبول صلاحية Sheets |
| 403 | إضافة المستخدم في OAuth test users |
| Android | SHA-1 + google-services.json |

---

## 4) Supabase (اختياري)
1. نفّذ `supabase_schema.sql` في SQL Editor
2. من التطبيق (مدير النظام): الإدارة → Supabase → URL + Anon Key → حفظ
3. أعد تشغيل التطبيق

---

## 5) مدير النظام (رئيس دائرة الاتصالات)
- ferasnatof@gmail.com
- gfa437926@gmail.com

إضافة بريد آخر من شاشة **الإدارة**.

---

## 6) التشغيل
```bash
flutter run
# أو
flutter build apk
```

## 7) الاستخدام اليومي
1. دخول Google  
2. إضافة أجهزة (الموديل يُقترح لاحقاً)  
3. بطاقات عهدة + رقم وطني + صور  
4. الفني يطلب → المدير يعتمد  
5. التقارير → Excel أو Google Sheets  
EOF
echo OK
ls -la /home/workdir/artifacts/asset_flow_flutter/SETUP.md
# Verify provider still valid
grep -n "exportFullExcel\|exportToGoogleSheets\|ImportResult" /home/workdir/artifacts/asset_flow_flutter/lib/providers/app_provider.dart | head -15
# Check duplicate class closing
tail -30 /home/workdir/artifacts/asset_flow_flutter/lib/providers/app_provider.dart
