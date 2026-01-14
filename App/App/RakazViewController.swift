import UIKit
import WebKit
import Capacitor

/**
 * RakazViewController - المتحكم الرئيسي للـ WebView في تطبيق RAKAZ iOS
 * مسؤول عن:
 * - حقن معرف التطبيق الأصلي
 * - معالجة أخطاء الشبكة
 * - التعامل مع Deep Links
 * - إخفاء Splash Screen
 */
class RakazViewController: CAPBridgeViewController {

    // MARK: - Constants
    private let TAG = "RakazViewController"

    /// JavaScript لحقن معرف التطبيق الأصلي - هام جداً لكي يتعرف Laravel على نوع التطبيق
    private let NATIVE_IDENTIFIER_JS = """
        window.isRakazNative = true;
        window.RAKAZ_NATIVE_APP = true;
        window.RAKAZ_PLATFORM = 'ios';
        window.RAKAZ_IOS_HANDSHAKE = 'RakazApp-Capacitor-iOS';
        document.documentElement.classList.add('rakaz-native-app');
        document.documentElement.classList.add('rakaz-ios-app');
        document.documentElement.setAttribute('data-rakaz-native', 'true');
        document.documentElement.setAttribute('data-rakaz-platform', 'ios');
        if (document.body) {
            document.body.classList.add('rakaz-native-app');
            document.body.classList.add('rakaz-ios-app');
            document.body.setAttribute('data-rakaz-native', 'true');
            document.body.setAttribute('data-rakaz-platform', 'ios');
        }
        window.dispatchEvent(new CustomEvent('rakazNativeReady', { detail: { platform: 'ios', handshake: 'RakazApp-Capacitor-iOS' } }));
        console.log('[RakazApp] iOS Native identifier injected - Handshake: RakazApp-Capacitor-iOS');
    """

    /// JavaScript لإخفاء Splash Screen
    private let HIDE_SPLASH_JS = """
        if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.SplashScreen) {
            window.Capacitor.Plugins.SplashScreen.hide();
        }
    """

    /// JavaScript للإشعار بـ Payment Callback
    private let PAYMENT_CALLBACK_JS = """
        window.dispatchEvent(new CustomEvent('paymentCallback', { detail: { url: '%@' } }));
        if (window.onPaymentCallback) { window.onPaymentCallback('%@'); }
    """

    // MARK: - Properties
    private var splashHidden = false
    private var isShowingErrorPage = false
    private var webView: WKWebView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("[\(TAG)] viewDidLoad")
        setupWebViewObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // الحصول على WebView من Capacitor Bridge
        if let bridge = self.bridge {
            webView = bridge.webView
            setupWebViewDelegates()
        }
    }

    // MARK: - WebView Setup
    private func setupWebViewDelegates() {
        guard let webView = webView else {
            print("[\(TAG)] WebView not available, retrying...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.setupWebViewDelegates()
            }
            return
        }

        webView.navigationDelegate = self

        // Fallback: إخفاء Splash بعد 5 ثوانٍ
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, !self.splashHidden else { return }
            self.hideSplashScreen()
        }

        print("[\(TAG)] WebView delegates setup complete")
    }

    private func setupWebViewObservers() {
        // مراقبة الإشعارات للـ Deep Links
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeepLink(_:)),
            name: NSNotification.Name("RakazPaymentCallback"),
            object: nil
        )
    }

    // MARK: - Deep Link Handling
    @objc func handleDeepLink(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }

        print("[\(TAG)] Deep link received: \(url.absoluteString)")
        handlePaymentCallback(url: url)
    }

    func handlePaymentCallback(url: URL) {
        var callbackURL = "https://www.rakaz.store/payment/callback"

        // استخراج معرف الدفع من الـ URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let paymentId = components.queryItems?.first(where: { $0.name == "paymentId" })?.value {
                callbackURL += "?paymentId=\(paymentId)"
            } else if let invoiceId = components.queryItems?.first(where: { $0.name == "Id" })?.value {
                callbackURL += "?paymentId=\(invoiceId)"
            }
        }

        print("[\(TAG)] Loading callback URL: \(callbackURL)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let webView = self.webView else { return }

            // إشعار JavaScript بالـ callback
            let js = String(format: self.PAYMENT_CALLBACK_JS, callbackURL, callbackURL)
            webView.evaluateJavaScript(js, completionHandler: nil)

            // تحميل صفحة callback
            if let url = URL(string: callbackURL) {
                webView.load(URLRequest(url: url))
            }
        }
    }

    // MARK: - Native Identifier Injection
    private func injectNativeIdentifier() {
        webView?.evaluateJavaScript(NATIVE_IDENTIFIER_JS) { [weak self] _, error in
            if let error = error {
                print("[\(self?.TAG ?? "RakazVC")] Error injecting native identifier: \(error)")
            } else {
                print("[\(self?.TAG ?? "RakazVC")] Native identifier injected successfully")
            }
        }
    }

    // MARK: - Splash Screen
    private func hideSplashScreen() {
        guard !splashHidden else { return }
        splashHidden = true

        webView?.evaluateJavaScript(HIDE_SPLASH_JS, completionHandler: nil)
        print("[\(TAG)] Splash screen hidden")
    }

    // MARK: - Error Page
    private func showErrorPage() {
        guard !isShowingErrorPage else {
            print("[\(TAG)] Already showing error page")
            return
        }

        isShowingErrorPage = true
        print("[\(TAG)] Showing error page")

        // تحميل صفحة الخطأ من الـ assets
        if let errorPagePath = Bundle.main.path(forResource: "error", ofType: "html", inDirectory: "public") {
            let errorPageURL = URL(fileURLWithPath: errorPagePath)
            webView?.loadFileURL(errorPageURL, allowingReadAccessTo: errorPageURL.deletingLastPathComponent())
        } else {
            // Fallback HTML
            let fallbackHTML = """
            <!DOCTYPE html>
            <html dir="rtl" lang="ar">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>خطأ في الاتصال</title>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
                        color: white;
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 20px;
                    }
                    .container {
                        text-align: center;
                        max-width: 400px;
                    }
                    .icon { font-size: 80px; margin-bottom: 20px; }
                    h1 { font-size: 24px; margin-bottom: 15px; color: #c9a45c; }
                    p { font-size: 16px; color: #aaa; margin-bottom: 30px; line-height: 1.6; }
                    button {
                        background: linear-gradient(135deg, #c9a45c 0%, #d4af37 100%);
                        color: #1a1a1a;
                        border: none;
                        padding: 15px 40px;
                        font-size: 16px;
                        font-weight: bold;
                        border-radius: 30px;
                        cursor: pointer;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="icon">📡</div>
                    <h1>خطأ في الاتصال</h1>
                    <p>تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.</p>
                    <button onclick="location.reload()">إعادة المحاولة</button>
                </div>
            </body>
            </html>
            """
            webView?.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }

    // MARK: - Network Check
    private func isNetworkAvailable() -> Bool {
        // فحص بسيط للشبكة - يمكن تحسينه باستخدام Reachability
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WKNavigationDelegate
extension RakazViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let url = webView.url?.absoluteString ?? "unknown"
        print("[\(TAG)] Page started loading: \(url)")

        // إعادة تعيين حالة صفحة الخطأ
        if !url.contains("error.html") {
            isShowingErrorPage = false
        }

        // حقن معرف التطبيق مبكراً
        injectNativeIdentifier()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let url = webView.url?.absoluteString ?? ""
        print("[\(TAG)] Page finished loading: \(url)")

        // إعادة حقن المعرف بعد تحميل الصفحة
        injectNativeIdentifier()

        // إخفاء Splash بعد تحميل الموقع
        if !splashHidden && url.contains("rakaz.store") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.hideSplashScreen()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        print("[\(TAG)] Navigation error: \(nsError.code) - \(nsError.localizedDescription)")

        // أخطاء الشبكة الشائعة
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorCannotFindHost
        ]

        if networkErrorCodes.contains(nsError.code) {
            showErrorPage()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""

        // السماح بروابط الدفع لفتحها في Safari الخارجي
        // يشمل: MyFatoorah, Apple Pay, وجميع بوابات الدفع
        let paymentDomains = [
            "myfatoorah",
            "applepay",
            "apple.com/apple-pay",
            "payment.myfatoorah",
            "demo.myfatoorah",
            "portal.myfatoorah",
            "knet.com",
            "knetpay",
            "benefitpay",
            "stcpay"
        ]

        let isPaymentURL = paymentDomains.contains { domain in
            urlString.contains(domain) || host.contains(domain)
        }

        if isPaymentURL {
            print("[\(TAG)] Opening payment URL in Safari: \(url)")
            UIApplication.shared.open(url, options: [:]) { success in
                print("[\(self.TAG)] Safari opened: \(success)")
            }
            decisionHandler(.cancel)
            return
        }

        // التعامل مع Custom URL Scheme للرجوع من الدفع
        if url.scheme == "rakaz-app" || url.scheme == "rakazstore" {
            handlePaymentCallback(url: url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
