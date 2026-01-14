# GitHub Actions Configuration Guide

This directory contains GitHub Actions workflows for automated building and testing of the RAKAZ iOS application.

## Available Workflows

### 1. iOS Build (`ios-build.yml`)
**Purpose:** Builds the iOS application and creates archives

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual dispatch

**Jobs:**
- **build:** Compiles the app in Debug configuration
- **archive-and-export:** Creates release archives (main branch only)

**Artifacts:**
- `ios-app-debug`: Debug build outputs
- `ios-app-archive`: Release archive

### 2. Code Quality Check (`code-quality.yml`)
**Purpose:** Validates code quality and project configuration

**Triggers:**
- Pull requests to `main` or `develop`
- Push to `main` or `develop`

**Jobs:**
- **swift-lint:** Runs SwiftLint checks
- **validate-project:** Validates Xcode project structure
- **dependency-check:** Verifies all dependencies

## Setup Instructions

### For Public Repositories (No Code Signing)

1. **Enable GitHub Actions:**
   - Go to Repository Settings → Actions → General
   - Enable "Allow all actions and reusable workflows"

2. **Push the Code:**
   ```bash
   git add .
   git commit -m "Add GitHub Actions workflows"
   git push origin main
   ```

3. **Monitor Builds:**
   - Go to the "Actions" tab in your repository
   - View workflow runs and logs

### For Private Repositories (With Code Signing)

#### Prerequisites:
- Apple Developer Account
- Valid certificates and provisioning profiles

#### Step-by-Step Setup:

1. **Export Your Certificate:**
   ```bash
   # Open Keychain Access
   # Find your certificate: "iPhone Developer" or "Apple Development"
   # Right-click → Export "Name"
   # Save as .p12 with a password
   
   # Convert to base64
   base64 -i YourCertificate.p12 | pbcopy
   ```

2. **Export Provisioning Profile:**
   ```bash
   # Location: ~/Library/MobileDevice/Provisioning Profiles/
   # Or download from Apple Developer Portal
   
   # Convert to base64
   base64 -i YourProfile.mobileprovision | pbcopy
   ```

3. **Add GitHub Secrets:**
   
   Go to: Repository → Settings → Secrets and variables → Actions
   
   Add the following secrets:
   
   | Secret Name | Description | How to Get |
   |------------|-------------|------------|
   | `BUILD_CERTIFICATE_BASE64` | Your .p12 certificate (base64) | Step 1 above |
   | `P12_PASSWORD` | Password for .p12 file | Password you set |
   | `BUILD_PROVISION_PROFILE_BASE64` | Provisioning profile (base64) | Step 2 above |
   | `KEYCHAIN_PASSWORD` | Temporary keychain password | Any random string |
   | `APPLE_ID` | Your Apple ID email | Your Apple account |
   | `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password | Generate at appleid.apple.com |

4. **Update Team ID:**
   
   Edit `exportOptions.plist`:
   ```xml
   <key>teamID</key>
   <string>YOUR_TEAM_ID</string>
   ```
   
   Find your Team ID at: https://developer.apple.com/account

5. **Enable Code Signing in Workflow:**
   
   Uncomment the certificate import section in `.github/workflows/ios-build.yml`

6. **Update Provisioning Profile:**
   
   Edit `exportOptions.plist`:
   ```xml
   <key>provisioningProfiles</key>
   <dict>
       <key>com.rakaz.store</key>
       <string>YOUR_PROFILE_NAME</string>
   </dict>
   ```

## Advanced Configuration

### Custom Build Settings

Create `.github/workflows/custom-build.yml`:
```yaml
name: Custom Build

on:
  workflow_dispatch:
    inputs:
      configuration:
        description: 'Build configuration'
        required: true
        default: 'Release'
        type: choice
        options:
          - Debug
          - Release
      scheme:
        description: 'Xcode scheme'
        required: true
        default: 'App'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: |
          cd App
          xcodebuild build \
            -project App.xcodeproj \
            -scheme ${{ github.event.inputs.scheme }} \
            -configuration ${{ github.event.inputs.configuration }}
```

### Fastlane Integration

Install Fastlane:
```bash
gem install fastlane
cd ios
fastlane init
```

Update workflow to use Fastlane:
```yaml
- name: Build with Fastlane
  run: fastlane ios build
```

### TestFlight Upload

Add to workflow after export:
```yaml
- name: Upload to TestFlight
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
  run: |
    xcrun altool --upload-app \
      -f build/App.ipa \
      -u $APPLE_ID \
      -p $APPLE_APP_SPECIFIC_PASSWORD \
      --type ios
```

## Troubleshooting

### Build Fails: "No matching provisioning profiles"
- Check that your provisioning profile is valid
- Ensure Bundle ID matches: `com.rakaz.store`
- Verify Team ID in exportOptions.plist

### Build Fails: "Swift package resolution failed"
- Ensure `package.json` exists with all dependencies
- Check network connectivity in runner
- Try clearing package cache

### Workflow Doesn't Trigger
- Check branch names match exactly
- Verify workflow file is in `.github/workflows/`
- Check repository Actions settings

### Certificate Import Fails
- Verify base64 encoding is correct
- Check P12_PASSWORD matches your certificate
- Ensure certificate is not expired

## Best Practices

1. **Always use secrets for sensitive data**
   - Never commit certificates or passwords
   - Use GitHub Secrets for all credentials

2. **Test locally first**
   ```bash
   cd App
   xcodebuild clean build -project App.xcodeproj -scheme App
   ```

3. **Use caching for faster builds**
   - Swift Package Manager cache
   - CocoaPods cache (if using)
   - DerivedData cache

4. **Monitor workflow usage**
   - Free tier: 2000 minutes/month for private repos
   - macOS runners count as 10x multiplier

5. **Version control your workflows**
   - Test workflow changes in feature branches
   - Use pull requests for workflow updates

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Capacitor iOS Guide](https://capacitorjs.com/docs/ios)

## Support

For issues with workflows:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Open an issue with error logs
