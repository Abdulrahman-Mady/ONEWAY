# دليل نشر تطبيق ONEWAY على Google Play

## 1. معرّف التطبيق (Package ID) وربطه بـ Firebase
تم اعتماد معرّف التطبيق الرسمي **`com.onewayegypt.app`** وربطه بالفعل داخل `android/app/google-services.json` (مشروع `oneway-f665d`).
> **مهم جداً لعمل Google Sign-In في نسخة المتجر:**
1. بعد إنشاء مفتاح الرفع (`upload-keystore.jks`) وتفعيل **Play App Signing** في Google Play Console، أضف بصمات `SHA-1` و`SHA-256` لكلٍ من **Upload key** و**App signing key** داخل **Firebase Console → Project Settings → Your Apps (`com.onewayegypt.app`)**.
2. حمّل ملف `google-services.json` المحدّث واستبدله بـ `android/app/google-services.json` قبل بناء النسخة النهائية.

---

## 2. إنشاء مفتاح التوقيع (Upload Keystore)
نفّذ الأمر التالي مرة واحدة واحفظ الملف وكلمات المرور في مكان آمن جداً (لا ترفعه على Git أبداً):

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

ثم انسخ `android/key.properties.template` إلى `android/key.properties` وضع فيه كلمات المرور:

```properties
storePassword=كلمة_مرور_المخزن
keyPassword=كلمة_مرور_المفتاح
keyAlias=upload
storeFile=../upload-keystore.jks
```

---

## 3. تسجيل بصمات SHA-1 و SHA-256 في Firebase (ضروري لـ Google Sign-In)
استخرج البصمات من مفتاح الـ release:
```powershell
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```
أضف بصمات `SHA-1` و `SHA-256` في **Firebase Console → Project Settings → Your Apps (Android)** ثم حمّل `google-services.json` المحدّث.
> **ملاحظة:** بعد تفعيل Google Play App Signing على Play Console، انسخ أيضاً `SHA-1` و `SHA-256` الخاصة بـ **App signing key certificate** من Play Console وأضفها في Firebase Console.

---

## 4. بناء ملف النشر (.aab)
```powershell
flutter clean
flutter pub get
flutter test
flutter build appbundle --release
```
الملف الناتج سيكون في:
`build/app/outputs/bundle/release/app-release.aab`

---

## 5. متطلبات Google Play Console (نموذج Data Safety والسياسات)
- **سياسة الخصوصية (Privacy Policy URL):** محتوى السياسة جاهز داخل التطبيق (`الإعدادات ← سياسة الخصوصية`) — انشر نفس النص على صفحة ويب (مثلاً GitHub Pages أو Firebase Hosting) وضع رابطها في Play Console.
- **حذف الحساب والبيانات (Account Deletion):** متوفر داخل التطبيق (`الإعدادات ← حذف الحساب والبيانات نهائياً`) — ضع رابط سياسة الخصوصية أو صفحة طلب الحذف في خانة Data Deletion بـ Play Console.
- **البيانات المُجمّعة في Data Safety:**
  - Personal info: Name, Email address, Phone number (optional) — App functionality, Account management.
  - Location: Approximate / Precise location (optional, in-use only for nearby places & SOS).
  - Photos: User-uploaded barrier photos (optional).
  - Audio: Voice search via microphone (processed on-device / not stored).
- **الإفصاحات (Declarations):**
  - التطبيق ليس تطبيقاً حكومياً (أرقام الطوارئ 123/122/180 مجرد اختصار اتصال).
  - أضف حساب اختبار (Test Account) في قسم **App Access** في Play Console ليتمكن مراجع Google من تجربة جميع الشاشات بسهولة.
