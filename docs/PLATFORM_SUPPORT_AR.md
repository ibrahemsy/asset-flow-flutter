# دعم المنصات - Asset Flow

يعتمد المشروع تطبيق Flutter واحداً بواجهات متجاوبة، مع إخراج مستقل لكل منصة. لا تستخدم نسخة سطح المكتب متصفحاً أو WebView.

## المنصات المستهدفة

| المنصة | أمر البناء | الناتج المتوقع |
|---|---|---|
| Web | `flutter build web --release` | ملفات ثابتة للنشر على استضافة ويب |
| Android | `flutter build apk --release` أو `flutter build appbundle --release` | APK للاختبار أو AAB لمتجر Google Play |
| Windows | `flutter build windows --release` | مجلد تشغيل أصلي يحتوي EXE ومكتباته |
| Linux | `flutter build linux --release` | حزمة تشغيل أصلية ومكتباتها |
| macOS | `flutter build macos --release` | تطبيق macOS بصيغة APP |
| iOS | `flutter build ios --release --no-codesign` | بناء غير موقّع للاختبار التقني فقط |

## ملاحظات مهمة قبل النشر

1. يجب تشغيل `flutterfire configure` لكل Firebase project حقيقي، وإضافة ملفات إعداد Firebase الصحيحة للمنصات المفعّلة. لا تستخدم قيم `YOUR_API_KEY` أو `YOUR_PROJECT_ID` في إصدار منشور.
2. فعّل Google Sign-In في Firebase Authentication واضبط OAuth client IDs وURL schemes وملفات إعداد Android/iOS/Web وفق تعليمات Firebase وGoogle لكل منصة.
3. تسجيل Google على Web يحتاج إعداد OAuth الخاص بنطاق الاستضافة، كما أن تطبيقات سطح المكتب تحتاج إعداد OAuth/deep-link مناسباً لكل نظام. نجاح التجميع وحده لا يثبت نجاح تسجيل الدخول.
4. بناء iOS باستخدام `--no-codesign` لا ينتج تطبيقاً جاهزاً للتوزيع. يلزم Apple Developer signing/provisioning لإنشاء IPA وتوزيعه.
5. حزم Windows وLinux وmacOS تحتاج اختباراً فعلياً على النظام المستهدف، بما في ذلك Google Sign-In واختيار الملفات ومشاركة Excel والطباعة.
6. لا تنشر Firestore Rules أو Cloud Functions قبل اختيار Firebase project الصحيح ومراجعة قواعد الوصول واختبارات Firebase Emulator.
7. لا تحفظ Service Account keys أو ملفات أسرار التوقيع أو كلمات المرور في Git. استخدم GitHub Actions Secrets/Environments عند إعداد النشر الموثوق.

## مخرجات CI

تُرفع المخرجات كـ GitHub Actions artifacts منفصلة بأسماء توضح المنصة. ملفات CI الحالية مخصصة للتحقق والبناء، ولا تعني أن التطبيق قد نُشر تلقائياً أو أن إعدادات Firebase الإنتاجية قد اكتملت.

## إعداد هوية الحزمة

قبل إصدار المتاجر، يجب اعتماد Bundle ID / Application ID رسمي لا يتغير بعد النشر، واسم التطبيق وأيقوناته ونسخة الإصدار. لا تعتمد معرف Flutter الافتراضي `com.example.*` لإصدار إنتاجي.
