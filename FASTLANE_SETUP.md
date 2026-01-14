# Fastlane Configuration (Optional)

## What is Fastlane?

Fastlane is a tool that automates building and releasing iOS apps. It can:
- Build and sign your app
- Take screenshots
- Upload to TestFlight
- Submit to App Store
- Run tests

## Installation

```bash
# Install Fastlane
sudo gem install fastlane

# Navigate to ios directory
cd ios

# Initialize Fastlane
fastlane init
```

## Sample Fastfile

Create `fastlane/Fastfile`:

```ruby
# Fastfile for RAKAZ iOS App

default_platform(:ios)

platform :ios do
  
  desc "Build the app"
  lane :build do
    gym(
      project: "App/App.xcodeproj",
      scheme: "App",
      clean: true,
      output_directory: "./build",
      output_name: "RAKAZ.ipa",
      export_method: "development"
    )
  end
  
  desc "Run tests"
  lane :test do
    run_tests(
      project: "App/App.xcodeproj",
      scheme: "App",
      devices: ["iPhone 15"]
    )
  end
  
  desc "Build and upload to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(
      xcodeproj: "App/App.xcodeproj"
    )
    
    # Build the app
    gym(
      project: "App/App.xcodeproj",
      scheme: "App",
      export_method: "app-store"
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
  
  desc "Release to App Store"
  lane :release do
    # Increment version
    increment_version_number(
      xcodeproj: "App/App.xcodeproj"
    )
    
    # Take screenshots
    snapshot
    
    # Build
    gym(
      project: "App/App.xcodeproj",
      scheme: "App",
      export_method: "app-store"
    )
    
    # Upload to App Store
    deliver(
      submit_for_review: false,
      automatic_release: false
    )
  end
  
  desc "Create screenshots"
  lane :screenshots do
    snapshot
  end
  
end
```

## Sample Appfile

Create `fastlane/Appfile`:

```ruby
app_identifier("com.rakaz.store")
apple_id("your-apple-id@example.com")
team_id("YOUR_TEAM_ID")

# For more information about the Appfile, see:
# https://docs.fastlane.tools/advanced/#appfile
```

## GitHub Actions Integration

Update `.github/workflows/ios-build.yml` to use Fastlane:

```yaml
- name: Install Fastlane
  run: |
    sudo gem install fastlane

- name: Build with Fastlane
  working-directory: ios
  run: |
    fastlane build
```

## Useful Fastlane Commands

```bash
# List all lanes
fastlane lanes

# Build app
fastlane build

# Run tests
fastlane test

# Upload to TestFlight
fastlane beta

# Full release
fastlane release

# Take screenshots
fastlane screenshots
```

## Environment Variables

Create `fastlane/.env`:

```bash
FASTLANE_USER=your-apple-id@example.com
FASTLANE_PASSWORD=your-password
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=app-specific-password
FASTLANE_TEAM_ID=YOUR_TEAM_ID
```

**Important:** Add `.env` to `.gitignore`!

## Documentation

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [iOS Beta Deployment Guide](https://docs.fastlane.tools/getting-started/ios/beta-deployment/)
- [App Store Deployment Guide](https://docs.fastlane.tools/getting-started/ios/appstore-deployment/)
