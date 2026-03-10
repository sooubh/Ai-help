import UIKit
import Flutter
import BackgroundTasks
import UserNotifications

/// CARE-AI AppDelegate
///
/// Responsibilities:
///   - Boots the Flutter engine (via FlutterAppDelegate)
///   - Registers the BGAppRefreshTask used for 3-hour progress updates
///   - Schedules the next refresh each time the task fires or the app becomes active
///   - Shows a local UNUserNotificationCenter notification from the background task
///
/// NOTE: "com.careai.care_ai.progressUpdate" must also appear in
///   Info.plist → BGTaskSchedulerPermittedIdentifiers.
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  private let bgTaskIdentifier = "com.careai.care_ai.progressUpdate"

  // ─── Application lifecycle ───────────────────────────────────────────────

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Boot Flutter engine and register all plugins
    GeneratedPluginRegistrant.register(with: self)

    // Register the BGAppRefreshTask handler
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: bgTaskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let task = task as? BGAppRefreshTask else { return }
      self?.handleProgressUpdateTask(task)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Schedule (or re-schedule) the next background refresh every time
  /// the app becomes active so the 3-hour interval is never stale.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    scheduleProgressUpdateTask()
  }

  // ─── BGTaskScheduler helpers ─────────────────────────────────────────────

  /// Submit a BGAppRefreshTaskRequest with a minimum 3-hour delay.
  private func scheduleProgressUpdateTask() {
    let request = BGAppRefreshTaskRequest(identifier: bgTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60 * 60) // 3 hours
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Non-fatal — OS may reject on simulator or when debugging
      NSLog("[CARE-AI] BGTaskScheduler submit failed: %@", error.localizedDescription)
    }
  }

  /// Called by the OS when the background refresh fires.
  /// Shows a local notification, then marks the task complete and reschedules.
  private func handleProgressUpdateTask(_ task: BGAppRefreshTask) {
    // Always reschedule before doing any work so the chain never breaks
    scheduleProgressUpdateTask()

    // Expiration handler — OS can terminate the task at any time
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    // Build and deliver a local notification
    let content = UNMutableNotificationContent()
    content.title = "CARE-AI Progress Update"
    content.body  = "Keep up the great work! Check your child's latest progress."
    content.sound = .default

    let requestId = "care_ai_bg_\(Int(Date().timeIntervalSince1970))"
    let notifRequest = UNNotificationRequest(
      identifier: requestId,
      content: content,
      trigger: nil  // deliver immediately
    )

    UNUserNotificationCenter.current().add(notifRequest) { error in
      if let error = error {
        NSLog("[CARE-AI] UNUserNotificationCenter add failed: %@", error.localizedDescription)
      }
      task.setTaskCompleted(success: error == nil)
    }
  }
}
