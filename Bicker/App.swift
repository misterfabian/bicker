import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    
    private let intervals: [(String, Int, String)] = [("Every Minute", 60, "1"), ("Every Hour", 3600, "2")]
    
    private var interval: Int {
        get {
            return UserDefaults.standard.object(forKey: "interval") as? Int ?? 3600
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "interval")
            setupMenu()
            schedule()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupBar()
        setupMenu()
        refresh()
        schedule()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
    
    private func setupBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Loading..."
        statusItem?.button?.action = #selector(toggle)
        statusItem?.button?.font = .systemFont(ofSize: 12, weight: .semibold)
    }
    
    private func setupMenu() {
        let mainMenu = NSMenu(title: "Bicker")
        let titleItem = NSMenuItem(title: "Bicker", action: nil, keyEquivalent: "")
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refresh), keyEquivalent: "r")
        let settingsItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        let settingsMenu = NSMenu()
        settingsMenu.items = intervals.map {
            let tempItem = NSMenuItem(title: $0.0, action: #selector(intervalPressed(_:)), keyEquivalent: $0.2)
            tempItem.tag = $0.1
            tempItem.state = interval == tempItem.tag ? .on : .off
            return tempItem
        }
        settingsItem.submenu = settingsMenu
        mainMenu.addItem(titleItem)
        //        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(refreshItem)
        mainMenu.addItem(settingsItem)
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(quitItem)
        statusItem?.menu = mainMenu
    }
    
    @objc private func refresh() {
        let link: String = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
        if let url = URL(string: link) {
            let task = URLSession(configuration: URLSessionConfiguration.ephemeral).dataTask(with: url) { data, _, _ in
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Int]] {
                    let price = json["bitcoin"]?["usd"] ?? 0
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.maximumFractionDigits = 0
                    formatter.currencySymbol = "$ "
                    DispatchQueue.main.async {
                        self.statusItem?.button?.title = formatter.string(from: price as NSNumber) ?? "Loading..."
                    }
                }
            }
            task.resume()
        }
    }
    
    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(interval), target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }
    
    @objc private func toggle() {
        if let menu = statusItem?.menu?.items.first {
            statusItem?.menu?.popUp(positioning: menu, at: NSPoint(x: 0, y: 0), in: nil)
        }
    }
    
    @objc private func intervalPressed(_ sender: NSMenuItem) {
        interval = sender.tag
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
}
