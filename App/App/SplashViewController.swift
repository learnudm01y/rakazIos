import UIKit
import WebKit
import SystemConfiguration

/**
 * SplashViewController - شاشة البداية مع Lottie Animation لتطبيق RAKAZ iOS
 * مطابقة لـ SplashActivity.java في Android
 * مدة العرض: 5 ثواني
 * مفتاح المصافحة: RakazApp-Capacitor-iOS
 */
class SplashViewController: UIViewController {

    // MARK: - Constants
    private let tag = "RakazSplash"
    private let splashDuration: TimeInterval = 5.0  // 5 seconds for full animation
    private let minSplashTime: TimeInterval = 3.0  // Minimum 3 seconds to show animation
    private let networkCheckTimeout: TimeInterval = 5.0  // 5 seconds timeout for network check

    // MARK: - Properties
    private var splashWebView: WKWebView!
    private var preloadWebView: WKWebView?
    private var websiteLoaded = false
    private var hasNetworkError = false
    private var animationComplete = false
    private var navigated = false
    private var networkCheckComplete = false
    private var hasInternet = false
    private var startTime: Date!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        startTime = Date()
        view.backgroundColor = .white

        print("[\(tag)] SplashViewController viewDidLoad")
        print("[\(tag)] Handshake Key: RakazApp-Capacitor-iOS")

        // Always show splash animation first
        setupSplashWebView()

        // Check internet in background
        checkInternetAsync()

        // Animation complete after splashDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) { [weak self] in
            guard let self = self else { return }
            self.animationComplete = true
            print("[\(self.tag)] Animation complete")
            self.checkAndNavigate()
        }
    }

    // MARK: - Setup Splash WebView with Lottie Animation
    private func setupSplashWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        splashWebView = WKWebView(frame: view.bounds, configuration: config)
        splashWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        splashWebView.backgroundColor = .white
        splashWebView.isOpaque = true
        splashWebView.scrollView.isScrollEnabled = false

        splashWebView.navigationDelegate = self

        view.addSubview(splashWebView)

        // Load splash.html with Lottie animation from public folder
        if let splashPath = Bundle.main.path(forResource: "splash", ofType: "html", inDirectory: "public") {
            let splashURL = URL(fileURLWithPath: splashPath)
            splashWebView.loadFileURL(splashURL, allowingReadAccessTo: splashURL.deletingLastPathComponent())
        } else {
            // Fallback - try alternative paths
            let paths = [
                "App/public/splash",
                "public/splash"
            ]
            for path in paths {
                if let url = Bundle.main.url(forResource: path, withExtension: "html") {
                    splashWebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                    return
                }
            }
            print("[\(tag)] Could not find splash.html")
        }
    }

    // MARK: - Internet Check
    private func checkInternetAsync() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var connected = false

            // First check basic connectivity
            if self.isNetworkAvailable() {
                // Then verify with actual HTTP request
                connected = self.canReachInternet()
            }

            print("[\(self.tag)] Internet check result: \(connected)")

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.networkCheckComplete = true
                self.hasInternet = connected

                if connected {
                    // Start preloading website
                    self.setupPreloadWebView()
                    if let url = URL(string: "https://www.rakaz.store/") {
                        self.preloadWebView?.load(URLRequest(url: url))
                    }
                } else {
                    // Wait for animation minimum time before showing error
                    let elapsed = Date().timeIntervalSince(self.startTime)
                    let remaining = max(0, self.minSplashTime - elapsed)
                    DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                        guard let self = self, !self.navigated else { return }
                        self.showErrorPage()
                    }
                }
            }
        }

        // Timeout for network check
        DispatchQueue.main.asyncAfter(deadline: .now() + networkCheckTimeout) { [weak self] in
            guard let self = self, !self.networkCheckComplete else { return }
            print("[\(self.tag)] Network check timeout, assuming connected")
            self.networkCheckComplete = true
            self.hasInternet = true
            // Assume connected and try to load
            if self.preloadWebView == nil {
                self.setupPreloadWebView()
                if let url = URL(string: "https://www.rakaz.store/") {
                    self.preloadWebView?.load(URLRequest(url: url))
                }
            }
        }
    }

    // MARK: - Actual Internet Reach Check
    private func canReachInternet() -> Bool {
        // Try to reach rakaz.store first
        if let url = URL(string: "https://www.rakaz.store/") {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 3.0

            let semaphore = DispatchSemaphore(value: 0)
            var success = false

            let task = URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 400)
                }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + 3.0)

            if success { return true }
        }

        // Try Google as fallback
        if let url = URL(string: "https://www.google.com/") {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 3.0

            let semaphore = DispatchSemaphore(value: 0)
            var success = false

            let task = URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 400)
                }
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + 3.0)

            return success
        }

        return false
    }

    // MARK: - Network Availability Check
    private func isNetworkAvailable() -> Bool {
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

    // MARK: - Setup Preload WebView
    private func setupPreloadWebView() {
        let config = WKWebViewConfiguration()

        preloadWebView = WKWebView(frame: .zero, configuration: config)
        preloadWebView?.isHidden = true
        preloadWebView?.navigationDelegate = self

        if let webView = preloadWebView {
            view.addSubview(webView)
        }
    }

    // MARK: - Error Page
    private func showErrorPage() {
        guard !navigated else { return }
        navigated = true

        print("[\(tag)] Showing error page")

        // Load error page from public folder
        if let errorPath = Bundle.main.path(forResource: "error", ofType: "html", inDirectory: "public") {
            let errorURL = URL(fileURLWithPath: errorPath)

            // Remove splash and show error
            splashWebView.loadFileURL(errorURL, allowingReadAccessTo: errorURL.deletingLastPathComponent())
        } else {
            // Fallback inline HTML
            let errorHTML = """
            <!DOCTYPE html>
            <html lang='ar' dir='rtl'>
            <head>
                <meta charset='UTF-8'>
                <meta name='viewport' 
                      content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    html, body { 
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                        background: #fff; height: 100%; display: flex; 
                        flex-direction: column; justify-content: center; 
                        align-items: center; padding: 20px; text-align: center; 
                    }
                    .container { 
                        max-width: 400px; width: 100%; display: flex; 
                        flex-direction: column; align-items: center; 
                    }
                    .icon { font-size: 80px; margin-bottom: 30px; }
                    h1 { font-size: 22px; color: #333; margin-bottom: 15px; }
                    p { font-size: 16px; color: #666; margin-bottom: 30px; }
                    button { 
                        background: linear-gradient(135deg, #4a4a4a 0%, #2d2d2d 100%); 
                        color: #fff; border: none; padding: 16px 50px; 
                        font-size: 18px; border-radius: 25px; cursor: pointer; 
                    }
                </style>
            </head>
            <body>
                <div class='container'>
                    <div class='icon'>📡</div>
                    <h1>لا يوجد اتصال بالإنترنت</h1>
                    <p>يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى</p>
                    <button onclick='location.reload()'>إعادة المحاولة | Retry</button>
                </div>
            </body>
            </html>
            """
            splashWebView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }

    // MARK: - Navigation Check
    private func checkAndNavigate() {
        guard !navigated else { return }

        print("[\(tag)] checkAndNavigate: animation=\(animationComplete), "
            + "loaded=\(websiteLoaded), error=\(hasNetworkError)")

        // Must wait for animation to complete
        if !animationComplete { return }

        // If we have network error and animation is complete, show error
        if hasNetworkError {
            showErrorPage()
            return
        }

        // If website loaded and animation complete, navigate
        if websiteLoaded {
            navigateToMainViewController()
        } else {
            // Animation complete but site not loaded - give it 3 more seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self, !self.navigated else { return }

                if self.websiteLoaded {
                    self.navigateToMainViewController()
                } else if self.hasNetworkError {
                    self.showErrorPage()
                } else {
                    // Still not loaded, navigate anyway
                    print("[\(self.tag)] Timeout - navigating anyway")
                    self.navigateToMainViewController()
                }
            }
        }
    }

    // MARK: - Navigate to Main
    private func navigateToMainViewController() {
        guard !navigated else { return }
        navigated = true

        print("[\(tag)] Navigating to RakazViewController")

        // Transition to the main storyboard
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mainVC = storyboard.instantiateInitialViewController() {
                mainVC.modalPresentationStyle = .fullScreen
                mainVC.modalTransitionStyle = .crossDissolve

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                        window.rootViewController = mainVC
                    }
                } else {
                    self.present(mainVC, animated: true)
                }
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        preloadWebView?.stopLoading()
        splashWebView?.stopLoading()
    }
}

// MARK: - WKNavigationDelegate
extension SplashViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView === preloadWebView {
            let url = webView.url?.absoluteString ?? ""
            if !hasNetworkError && url.contains("rakaz.store") {
                websiteLoaded = true
                print("[\(tag)] Website loaded successfully")
                checkAndNavigate()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if webView === preloadWebView {
            handleWebViewError(error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if webView === preloadWebView {
            handleWebViewError(error)
        }
    }

    private func handleWebViewError(_ error: Error) {
        let nsError = error as NSError
        print("[\(tag)] WebView error: \(nsError.code) - \(nsError.localizedDescription)")

        // Network error codes
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorCannotFindHost
        ]

        if networkErrorCodes.contains(nsError.code) {
            hasNetworkError = true
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Allow error page retry button to reload
        if webView === splashWebView {
            if let url = navigationAction.request.url?.absoluteString,
               url.contains("rakaz.store") {
                // Restart the splash process
                navigated = false
                hasNetworkError = false
                websiteLoaded = false
                animationComplete = false
                startTime = Date()

                setupSplashWebView()
                checkInternetAsync()

                DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) { [weak self] in
                    guard let self = self else { return }
                    self.animationComplete = true
                    self.checkAndNavigate()
                }

                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }
}
