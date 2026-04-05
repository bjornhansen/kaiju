import Foundation
import os

/// App-wide logging helper
enum KaijuLogger {
    static let auth = Logger(subsystem: "com.kaiju.app", category: "Auth")
    static let api = Logger(subsystem: "com.kaiju.app", category: "API")
    static let sync = Logger(subsystem: "com.kaiju.app", category: "Sync")
    static let store = Logger(subsystem: "com.kaiju.app", category: "Store")
    static let webhook = Logger(subsystem: "com.kaiju.app", category: "Webhook")
    static let notification = Logger(subsystem: "com.kaiju.app", category: "Notification")
    static let ui = Logger(subsystem: "com.kaiju.app", category: "UI")
}
