import Cocoa
import UniformTypeIdentifiers
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private static let backendURL = URL(string: "http://127.0.0.1:8010")!
    private static let healthURL = URL(string: "http://127.0.0.1:8010/health")!

    private var window: NSWindow!
    private var webView: WKWebView!
    private var backendProcess: Process?
    private let backendInstanceID = UUID().uuidString
    private var readinessDeadline = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("Native shell starting.")
        NSApp.setActivationPolicy(.regular)
        createWindow()
        startBackend()
        waitForBackend()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        log("Native shell terminating.")
        stopBackend()
    }

    private func createWindow() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.add(self, name: "pdfNupSaveFile")

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(loadingHTML(), baseURL: nil)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PDF N-up Tool"
        window.minSize = NSSize(width: 960, height: 640)
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func startBackend() {
        guard let resourcesURL = Bundle.main.resourceURL else {
            log("Bundle resource URL is missing.")
            showFatalError("Cannot locate app resources.")
            return
        }

        log("Resource URL: \(resourcesURL.path)")
        let backendExecutableURL = resourcesURL
            .appendingPathComponent("BackendRuntime", isDirectory: true)
            .appendingPathComponent("PDF N-up Backend")

        log("Backend executable URL: \(backendExecutableURL.path)")
        guard FileManager.default.isExecutableFile(atPath: backendExecutableURL.path) else {
            log("Backend executable is missing or not executable.")
            showFatalError("Cannot locate bundled backend runtime.")
            return
        }

        let process = Process()
        process.executableURL = backendExecutableURL
        process.currentDirectoryURL = backendExecutableURL.deletingLastPathComponent()

        var environment = ProcessInfo.processInfo.environment
        environment["PDFNUPTOOL_OPEN_BROWSER"] = "0"
        environment["PDFNUPTOOL_ENABLE_HEARTBEAT_SHUTDOWN"] = "0"
        environment["PDFNUPTOOL_NATIVE_SHELL"] = "1"
        environment["PDFNUPTOOL_PARENT_PID"] = String(ProcessInfo.processInfo.processIdentifier)
        environment["PDFNUPTOOL_INSTANCE_ID"] = backendInstanceID
        process.environment = environment

        do {
            try process.run()
            log("Backend process started with pid \(process.processIdentifier).")
            backendProcess = process
        } catch {
            log("Failed to start backend: \(error.localizedDescription)")
            showFatalError("Failed to start bundled backend: \(error.localizedDescription)")
        }
    }

    private func waitForBackend() {
        readinessDeadline = Date().addingTimeInterval(60)
        pollBackend()
    }

    private func pollBackend() {
        var request = URLRequest(url: Self.healthURL)
        request.timeoutInterval = 2

        URLSession.shared.dataTask(with: request) { data, response, _ in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let instanceID = self.healthInstanceID(from: data)
            DispatchQueue.main.async {
                if statusCode == 200 && instanceID == self.backendInstanceID {
                    self.log("Backend health check passed with matching instance \(self.backendInstanceID).")
                    self.webView.load(self.frontendRequest())
                    return
                }

                if statusCode == 200 {
                    self.log("Ignoring health response from a different backend instance.")
                }

                if let process = self.backendProcess, !process.isRunning {
                    self.log("Backend process exited before matching health check.")
                    self.showFatalError("Backend exited before the app became ready. Another PDF N-up Tool instance may already be running on port 8010.")
                    return
                }

                if Date() > self.readinessDeadline {
                    self.log("Backend health check timed out.")
                    self.showFatalError("Backend did not become ready. Check ~/Library/Application Support/PDF N-up Tool/app-launcher.log.")
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.pollBackend()
                }
            }
        }.resume()
    }

    private func frontendRequest() -> URLRequest {
        var components = URLComponents(url: Self.backendURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "native_instance", value: backendInstanceID),
        ]
        let url = components?.url ?? Self.backendURL
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30
        )
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        return request
    }

    private func healthInstanceID(from data: Data?) -> String? {
        guard let data else {
            return nil
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let object = json as? [String: Any]
            return object?["instance_id"] as? String
        } catch {
            return nil
        }
    }

    private func stopBackend() {
        guard let process = backendProcess else {
            return
        }

        if process.isRunning {
            log("Terminating backend process \(process.processIdentifier).")
            process.terminate()
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
                if process.isRunning {
                    process.interrupt()
                }
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "pdfNupSaveFile",
              let body = message.body as? [String: Any],
              let filename = body["filename"] as? String,
              let base64 = body["base64"] as? String,
              let data = Data(base64Encoded: base64) else {
            showAlert(title: "Export Failed", message: "The exported PDF could not be prepared for saving.")
            return
        }

        saveExportedPDF(data: data, suggestedFilename: sanitizedFilename(filename))
    }

    private func saveExportedPDF(data: Data, suggestedFilename: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [UTType.pdf]

        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else {
                return
            }

            do {
                try data.write(to: url, options: .atomic)
            } catch {
                self.showAlert(title: "Save Failed", message: error.localizedDescription)
            }
        }
    }

    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.pdf]

        panel.beginSheetModal(for: window) { response in
            completionHandler(response == .OK ? panel.urls : nil)
        }
    }

    private func showFatalError(_ message: String) {
        showAlert(title: "PDF N-up Tool", message: message) {
            NSApp.terminate(nil)
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window) { _ in
            completion?()
        }
    }

    private func sanitizedFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let cleaned = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? "merged.pdf" : cleaned
    }

    private func loadingHTML() -> String {
        """
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              html, body {
                width: 100%;
                height: 100%;
                margin: 0;
                background: #f6f7f9;
                color: #1d2430;
                font: 15px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              }
              body {
                display: grid;
                place-items: center;
              }
              main {
                display: grid;
                gap: 10px;
                justify-items: center;
              }
              h1 {
                margin: 0;
                font-size: 18px;
                font-weight: 650;
              }
              p {
                margin: 0;
                color: #586170;
              }
            </style>
          </head>
          <body>
            <main>
              <h1>PDF N-up Tool</h1>
              <p>Starting local service...</p>
            </main>
          </body>
        </html>
        """
    }

    private func log(_ message: String) {
        do {
            let directory = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/PDF N-up Tool", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("native-shell.log")
            let line = "[\(Date())] \(message)\n"

            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let handle = try FileHandle(forWritingTo: fileURL)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } else {
                    try data.write(to: fileURL)
                }
            }
        } catch {
            NSLog("PDF N-up Tool native shell log error: \(error.localizedDescription)")
        }
    }
}
