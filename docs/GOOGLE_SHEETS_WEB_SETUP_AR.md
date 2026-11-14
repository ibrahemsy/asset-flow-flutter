# إعداد Google Sign-In والويب لـ Google Sheets

## ما تم في الكود
- `web/index.html` يحتوي `google-signin-client_id`
- `GoogleSignIn(clientId: ...)` في خدمة Firebase مع صلاحية `spreadsheets`

## على جهازك بعد السحب من GitHub

```bat
cd C:\Users\LENOVO\asset-flow-flutter
git fetch origin
git checkout security/firebase-rules-bootstrap
git pull origin security/firebase-rules-bootstrap
flutter create .
flutter pub get
flutter run -d chrome
```

`flutter create .` يكمّل ملفات المنصات الناقصة (أيقونات الويب وغيرها) دون مسح `lib`.

## Google Cloud (مشروع ibrahemov)
1. تفعيل Google Sheets API
2. OAuth Client من نوع Web
3. Authorized JavaScript origins:
   - http://localhost
   - http://localhost:PORT (المنفذ الذي يظهر عند التشغيل)
4. لا تضع `client_secret` داخل المشروع أبداً

## الاستخدام
1. دخول Google والموافقة على صلاحية الجداول
2. التقارير → تصدير إلى Google Sheets
