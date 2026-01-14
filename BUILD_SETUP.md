# iOS Build Configuration

## ملف GitHub Actions Workflow

تم إنشاء ملف `.github/workflows/ios-build.yml` لبناء تطبيق iOS على GitHub Actions.

## المتطلبات الأساسية

### 1. Node.js Dependencies
إذا كان المشروع يعتمد على Capacitor من node_modules، يجب إضافة `package.json` في جذر المشروع:

```json
{
  "name": "rakaz-ios",
  "version": "1.0.0",
  "dependencies": {
    "@capacitor/core": "^8.0.0",
    "@capacitor/ios": "^8.0.0",
    "@capacitor/app": "^8.0.0",
    "@capacitor/browser": "^8.0.0",
    "@capacitor/haptics": "^8.0.0",
    "@capacitor/keyboard": "^8.0.0",
    "@capacitor/splash-screen": "^8.0.0",
    "@capacitor/status-bar": "^8.0.0"
  }
}
```

### 2. Code Signing (للإنتاج)

لإنشاء IPA قابل للتوزيع، تحتاج إلى إعداد GitHub Secrets التالية:

#### Secrets المطلوبة:
- `BUILD_CERTIFICATE_BASE64`: شهادة Apple Developer (بصيغة .p12 مشفرة base64)
- `P12_PASSWORD`: كلمة مرور ملف .p12
- `BUILD_PROVISION_PROFILE_BASE64`: ملف Provisioning Profile (مشفر base64)
- `KEYCHAIN_PASSWORD`: كلمة مرور مؤقتة للـ Keychain

#### خطوات إنشاء Secrets:

1. **تصدير الشهادة من Keychain:**
   ```bash
   # تصدير الشهادة
   security find-identity -v -p codesigning
   
   # تحويلها إلى base64
   base64 -i certificate.p12 | pbcopy
   ```

2. **تصدير Provisioning Profile:**
   ```bash
   base64 -i profile.mobileprovision | pbcopy
   ```

3. **إضافة Secrets إلى GitHub:**
   - اذهب إلى: Repository Settings → Secrets and variables → Actions
   - أضف كل Secret بالقيمة المناسبة

### 3. ExportOptions.plist (للتوزيع)

إذا كنت تريد إنشاء IPA، أنشئ ملف `exportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.rakaz.store</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

## ميزات الـ Workflow

### Build Job
- يبني التطبيق في وضع Debug
- لا يتطلب Code Signing
- يرفع مخرجات البناء كـ Artifacts
- يعمل على جميع الـ Pushes والـ Pull Requests

### Archive Job
- يعمل فقط على branch main
- يقوم بعمل Archive للتطبيق
- يحتاج Code Signing للتوزيع الفعلي

## النقاط المهمة

### مشاكل محتملة:

1. **Swift Package Dependencies:**
   - الـ Package.swift يشير إلى `node_modules` في مسار نسبي
   - تأكد من وجود `package.json` وتثبيت Dependencies قبل البناء

2. **الملفات المولدة:**
   - `capacitor.config.json` و `config.xml` في .gitignore
   - لكنها موجودة في المشروع - قد تحتاج إلى إزالتها من .gitignore

3. **Code Sign Identity:**
   - البناء الحالي يتجاوز Code Signing
   - للنشر الفعلي، ستحتاج إلى إعداد الشهادات

## الاستخدام

### تشغيل الـ Workflow:

1. **تلقائياً:** عند Push أو Pull Request على main/develop
2. **يدوياً:** من تبويب Actions في GitHub → اختر "iOS Build" → Run workflow

### الحصول على المخرجات:

بعد نجاح البناء، ستجد Artifacts في صفحة الـ Workflow:
- `ios-app-debug`: مخرجات البناء
- `ios-app-archive`: Archive الكامل (على main branch فقط)

## التطوير المستقبلي

- [ ] إضافة Unit Tests
- [ ] إضافة UI Tests
- [ ] تفعيل Code Signing الكامل
- [ ] رفع IPA إلى TestFlight تلقائياً
- [ ] إعداد Fastlane للتوزيع الآلي

## الدعم

للمزيد من المعلومات:
- [GitHub Actions for iOS](https://docs.github.com/en/actions/deployment/deploying-xcode-applications)
- [Capacitor iOS Documentation](https://capacitorjs.com/docs/ios)
