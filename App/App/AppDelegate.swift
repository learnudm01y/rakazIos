import UIKit
import Capacitor
import SystemConfiguration

/**
 * RAKAZ iOS AppDelegate
 * معالجة Deep Links للدفع و Universal Links
 * مفتاح المصافحة: RakazApp-Capacitor-iOS
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let TAG = "RakazAppDelegate"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // تسجيل معلومات التطبيق
        print("[\(TAG)] RAKAZ iOS App Started")
        print("[\(TAG)] Handshake Key: RakazApp-Capacitor-iOS")

        // إنشاء النافذة وعرض SplashViewController
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = SplashViewController()
        window?.makeKeyAndVisible()

        // فحص إذا تم فتح التطبيق من Deep Link
        if let url = launchOptions?[.url] as? URL {
            print("[\(TAG)] App launched with URL: \(url)")
            // تأخير معالجة الـ URL حتى يتم تحميل التطبيق
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                self?.handleIncomingURL(url)
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // التطبيق على وشك الانتقال من الحالة النشطة إلى غير النشطة
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // التطبيق دخل الخلفية - حفظ البيانات إن لزم
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // التطبيق على وشك العودة للمقدمة
        print("[\(TAG)] App returning to foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // التطبيق أصبح نشطاً - إعادة تحديث الواجهة إن لزم
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // التطبيق على وشك الإغلاق
    }

    // MARK: - URL Scheme Handling (Deep Links)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("[\(TAG)] App opened with URL: \(url)")

        // معالجة روابط الدفع
        if handlePaymentURL(url) {
            return true
        }

        // تمرير للـ Capacitor إذا لم يكن رابط دفع
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    // MARK: - Universal Links Handling
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("[\(TAG)] Universal Link activity received")

        // معالجة Universal Links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            print("[\(TAG)] Universal Link URL: \(url)")

            if handlePaymentURL(url) {
                return true
            }
        }

        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    // MARK: - Payment URL Handling
    private func handlePaymentURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        let scheme = url.scheme?.lowercased() ?? ""

        // التحقق من روابط الدفع
        let isPaymentCallback = scheme == "rakaz-app" ||
                                urlString.contains("payment/callback") ||
                                urlString.contains("payment-callback") ||
                                urlString.contains("myfatoorah")

        if isPaymentCallback {
            print("[\(TAG)] Payment callback detected: \(url)")
            handleIncomingURL(url)
            return true
        }

        // روابط RAKAZ العادية
        if urlString.contains("rakaz.store") {
            handleIncomingURL(url)
            return true
        }

        return false
    }

    // MARK: - URL Processing
    private func handleIncomingURL(_ url: URL) {
        print("[\(TAG)] Processing incoming URL: \(url)")

        // إرسال إشعار للـ ViewController
        NotificationCenter.default.post(
            name: NSNotification.Name("RakazPaymentCallback"),
            object: nil,
            userInfo: ["url": url]
        )
    }
}
