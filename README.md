# ONEWAY - مصر بدون عوائق

تطبيق Flutter لمساعدة مستخدمي الكراسي المتحركة في مصر على إيجاد الأماكن المجهزة،
مع خريطة تفاعلية، بلاغات عوائق، زر استغاثة، ومساعد صوتي بالعربي.

الباك إند: Firebase (مشروع `oneway-f665d`) - Auth, Firestore, Storage, Cloud Functions.

## التشغيل محلياً

1. `flutter pub get`
2. ظبط مفتاح الخرايط (تحت) - من غيره الخريطة مش هتفتح.
3. `flutter run`

## الإعدادات المطلوبة (مرة واحدة لكل جهاز/مشروع)

### 1. مفتاح Google Maps
- أنشئ مفتاح من Google Cloud Console وقيّده بـ Maps SDK for Android/iOS.
- Android: حط `MAPS_API_KEY=المفتاح` في `android/local.properties`
  (شوف `android/local.properties.template`).
- iOS: انسخ `ios/Flutter/MapsKeys.xcconfig.template` إلى `MapsKeys.xcconfig`
  وحط المفتاح فيه. الملفين دول متجاهلين في git عمداً - المفتاح ميترفعش أبداً.

### 2. تسجيل الدخول بجوجل
- في Firebase Console: Authentication > Sign-in method > فعّل Google.
- أضف بصمة SHA-1 بتاعة الـ keystore بتاع جهازك للتطبيق في إعدادات المشروع،
  وحمّل `google-services.json` الجديد مكان القديم.
  (استخرج البصمة بـ `cd android && ./gradlew signingReport`).

### 3. نشر القواعد والـ Functions
```
cd firebase
npm install --prefix functions
firebase deploy --only firestore:rules,storage:rules,functions
```

### 4. تعيين نفسك سوبر أدمن (أول مرة بس)
```
firebase functions:config:set oneway.initial_admin_email="ايميلك@example.com"
firebase deploy --only functions
```
سجّل حساب بنفس الإيميل في التطبيق، بعدين افتح صفحة `/admin/setup`
أو استدعِ `bootstrapInitialSuperAdmin` - حصلت على superAdmin.

### 5. إضافة أيميلات أدمن تانية (اللي بتحددها أنت)
- الأدمن بيتعين من السيرفر بس، ومفيش أي زرار أو صفحة أدمن بتظهر لغير المصرح لهم.
- أضف إيميل لقائمة الأدمن المعينين من التطبيق (زرار في لوحة الأدمن لاحقاً) أو يدوياً:
  أنشئ/عدّل وثيقة `admin_config/allowed_admin_emails` في Firestore وحط فيها
  `{ "emails": ["admin1@example.com"] }`.
- أي حد بيسجل بإيميل موجود في القايمة بياخد دور admin تلقائياً، والحسابات
  الموجودة بتستدعي `claimDesignatedAdminRole`. الإضافة/الحذف من التطبيق
  متاحين للسوبر أدمن بس عبر `addAllowedAdminEmail` / `removeAllowedAdminEmail`.

### 6. زراعة الأماكن الأولية
- من لوحة الأدمن > المؤشرات > "استيراد الأماكن المعتمدة الأولية" (8 أماكن)، أو
- من الجهاز: `cd firebase && node seed_places.js`
  (محتاج `GOOGLE_APPLICATION_CREDENTIALS` تشاور على service account key -
  المفتاح ده سري وميترفعش على git أبداً).

### 7. المساعد الذكي (Gemini)
```
firebase functions:config:set oneway.gemini_api_key="المفتاح"
firebase deploy --only functions
```
من غير المفتاح المساعد بيرجع تلقائياً لمحرك الكلمات المفتاحية المحلي، فمفيش حاجة بتبوظ.

## ملاحظات أمان
- `key.properties`, `local.properties`, `MapsKeys.xcconfig`, service account keys:
  كلها في `.gitignore` ومينفعش تترفع على الريبو.
- قبل النشر على Play Store: ظبط توقيع release حقيقي في `android/key.properties`
  (الحالي بيستخدم مفاتيح debug).
