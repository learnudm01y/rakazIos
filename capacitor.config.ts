import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.rakaz.store',
  appName: 'RAKAZ',
  webDir: 'App/App/public',
  server: {
    url: 'https://www.rakaz.store/',
    cleartext: true,
    allowNavigation: ['*']
  },
  android: {
    allowMixedContent: true,
    webContentsDebuggingEnabled: true,
    overrideUserAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36 RakazApp-Capacitor-Android'
  },
  ios: {
    scheme: 'App',
    path: 'App',
    overrideUserAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1 RakazApp-Capacitor-iOS',
    contentInset: 'automatic',
    allowsLinkPreview: true,
    scrollEnabled: true,
    limitsNavigationsToAppBoundDomains: false,
    preferredContentMode: 'mobile'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 5000,
      launchAutoHide: false,
      backgroundColor: '#ffffffff',
      androidScaleType: 'CENTER_CROP',
      iosSpinnerStyle: 'small',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true
    },
    Browser: {
      presentationStyle: 'fullscreen'
    }
  }
};

export default config;