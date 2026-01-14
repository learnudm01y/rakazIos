# RAKAZ iOS Application

<div dir="rtl">

## نظرة عامة

تطبيق RAKAZ لنظام iOS مبني باستخدام Capacitor وSwift. يتيح التطبيق الوصول إلى متجر RAKAZ عبر واجهة أصلية محسّنة لأجهزة iOS.

## المواصفات التقنية

- **Bundle ID:** com.rakaz.store
- **اسم التطبيق:** RAKAZ
- **إصدار iOS الأدنى:** 15.0
- **إصدار Swift:** 5.0
- **Xcode:** 15.2+
- **Capacitor:** 8.0.0

## البنية التقنية

### Capacitor Plugins
- **@capacitor/app** - إدارة دورة حياة التطبيق
- **@capacitor/browser** - فتح الروابط في المتصفح
- **@capacitor/haptics** - الاهتزازات اللمسية
- **@capacitor/keyboard** - إدارة لوحة المفاتيح
- **@capacitor/splash-screen** - شاشة البداية
- **@capacitor/status-bar** - شريط الحالة

### المكونات الرئيسية

```
ios/
├── .github/workflows/     # GitHub Actions للبناء التلقائي
├── App/                   # مجلد المشروع الرئيسي
│   ├── App/              # ملفات التطبيق
│   │   ├── AppDelegate.swift
│   │   ├── RakazViewController.swift
│   │   ├── SplashViewController.swift
│   │   ├── Info.plist
│   │   └── Assets.xcassets/
│   ├── App.xcodeproj/    # مشروع Xcode
│   └── CapApp-SPM/       # Swift Package Manager
├── capacitor-cordova-ios-plugins/
├── package.json          # Dependencies
└── exportOptions.plist   # إعدادات التصدير
```

## المتطلبات

### للتطوير المحلي:
- macOS 13.0+
- Xcode 15.2+
- CocoaPods
- Node.js 18+
- npm أو yarn

### للبناء على GitHub Actions:
- حساب GitHub
- Apple Developer Account (للتوزيع)
- Certificates and Provisioning Profiles

## التثبيت والإعداد

### 1. استنساخ المشروع

```bash
git clone <repository-url>
cd ios
```

### 2. تثبيت Dependencies

```bash
npm install
```

### 3. فتح المشروع في Xcode

```bash
cd App
open App.xcodeproj
```

### 4. تحديث الإعدادات

في Xcode:
1. اختر الـ Target "App"
2. في تبويب "Signing & Capabilities":
   - حدد Team الخاص بك
   - تأكد من Bundle Identifier: `com.rakaz.store`

### 5. البناء والتشغيل

```bash
# البناء من Terminal
npm run ios:build

# أو من Xcode
Command + B (Build)
Command + R (Run)
```

## GitHub Actions

### إعداد البناء التلقائي

تم إنشاء workflow في `.github/workflows/ios-build.yml` يقوم بـ:

✅ بناء التطبيق تلقائياً على كل push
✅ اختبار التطبيق
✅ إنشاء Archive
✅ رفع Artifacts

### تفعيل Code Signing

لتوزيع التطبيق، أضف GitHub Secrets التالية:

1. **BUILD_CERTIFICATE_BASE64**
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

2. **P12_PASSWORD**
   كلمة مرور ملف الشهادة

3. **BUILD_PROVISION_PROFILE_BASE64**
   ```bash
   base64 -i profile.mobileprovision | pbcopy
   ```

4. **KEYCHAIN_PASSWORD**
   كلمة مرور عشوائية للـ Keychain المؤقت

راجع ملف [BUILD_SETUP.md](BUILD_SETUP.md) للتفاصيل الكاملة.

## الإعدادات المخصصة

### شاشة البداية (Splash Screen)

الإعدادات في `capacitor.config.json`:
- مدة العرض: 5000ms
- الإخفاء التلقائي: معطّل
- اللون: أبيض (#ffffffff)

### User Agent

تم تخصيص User Agent للتطبيق:
```
Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1 RakazApp-Capacitor-iOS
```

### Deep Links

URL Schemes المدعومة:
- `rakaz-app://`
- `rakazstore://`

## البناء للإنتاج

### 1. تحديث الإصدار

في Xcode → Target → General:
- Version: `1.0`
- Build: `1`

### 2. Archive

```bash
npm run ios:archive
```

أو من Xcode:
```
Product → Archive
```

### 3. التصدير

```
Window → Organizer → Archives → Distribute App
```

### 4. الرفع إلى App Store

استخدم Xcode Organizer أو:
```bash
xcrun altool --upload-app -f App.ipa -u USERNAME -p APP_SPECIFIC_PASSWORD
```

## استكشاف الأخطاء

### مشكلة: Swift Package Dependencies

```bash
cd App
xcodebuild -resolvePackageDependencies -project App.xcodeproj -scheme App
```

### مشكلة: Code Signing

تأكد من:
- اختيار Team الصحيح
- وجود Provisioning Profile صالح
- تطابق Bundle ID

### مشكلة: Build Failed

```bash
# تنظيف البناء
cd App
xcodebuild clean -project App.xcodeproj -scheme App

# إعادة البناء
xcodebuild build -project App.xcodeproj -scheme App
```

## الأوامر المفيدة

```bash
# تنظيف المشروع
npm run clean

# بناء Debug
npm run ios:build

# عمل Archive
npm run ios:archive

# عرض الأجهزة المتاحة
xcrun simctl list devices

# تشغيل على Simulator
xcodebuild -project App/App.xcodeproj -scheme App -destination 'platform=iOS Simulator,name=iPhone 15'
```

## الأمان

⚠️ **ملاحظات هامة:**
- لا تقم برفع Certificates أو Provisioning Profiles إلى Git
- استخدم GitHub Secrets للبيانات الحساسة
- راجع ملف `.gitignore` للتأكد من استبعاد الملفات الحساسة

## الدعم والمساهمة

للإبلاغ عن مشاكل أو اقتراحات:
1. افتح Issue في GitHub
2. قدم Pull Request مع وصف تفصيلي

## الترخيص

هذا المشروع خاص ولا يُسمح بتوزيعه بدون إذن.

---

**تم إنشاء الـ Workflow بواسطة:** GitHub Copilot
**التاريخ:** يناير 2026

</div>
