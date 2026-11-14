# إعداد Supabase لمشروع Asset Flow

## 1) إنشاء الجداول
1. افتح مشروعك في [Supabase Dashboard](https://supabase.com/dashboard)
2. **SQL Editor → New query**
3. الصق محتوى الملف `supabase_schema.sql` من المستودع
4. **Run**

## 2) تفعيل المصادقة
**Authentication → Providers**
- فعّل **Email**
- (اختياري) Google لاحقاً

## 3) إنشاء مستخدم تجريبي
**Authentication → Users → Add user**
- أدخل الإيميل وكلمة المرور
- أو سجّل من شاشة التطبيق (إن وُجد التسجيل)

## 4) المدير
البريد في `BackendConfig.adminEmails` يُعامل كمدير نظام.
الافتراضي الحالي يتضمن بريد المطور؛ عدّله حسب الحاجة.

## 5) التشغيل
```bat
cd C:\Users\LENOVO\asset-flow-flutter
git pull origin security/firebase-rules-bootstrap
flutter pub get
flutter run -d chrome --web-port=51212
```

الدخول: **إيميل + كلمة مرور** (ليس Google Firebase).

## أمان
- لا تضع كلمة مرور Postgres أو `service_role` في التطبيق
- إن ظهرت مفاتيح في دردشة أو Git عام: دوّرها من لوحة Supabase
- فعّل **RLS** على الجداول قبل الاستخدام الحقيقي
