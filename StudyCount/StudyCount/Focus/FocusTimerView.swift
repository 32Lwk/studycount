import Combine
import SwiftUI
import UserNotifications

/// アプリ内集中タイマー。バックグラウンドではローカル通知で完了を知らせる。
struct FocusTimerView: View {
    @State private var minutes: Int = 25
    @State private var secondsRemaining: Int = 0
    @State private var isRunning = false
    @State private var endDate: Date?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(timeString)
                    .font(.system(size: 56, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Stepper("分: \(minutes)", value: $minutes, in: 5 ... 180, step: 5)
                    .disabled(isRunning)
                    .padding(.horizontal)
                HStack {
                    Button(isRunning ? "停止" : "開始") {
                        if isRunning {
                            stop()
                        } else {
                            start()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Text("他アプリの利用制限（Screen Time）は行いません。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("集中タイマー")
            .onReceive(timer) { _ in
                tick()
            }
        }
    }

    private var timeString: String {
        let total = isRunning ? secondsRemaining : minutes * 60
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func start() {
        secondsRemaining = minutes * 60
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        isRunning = true
        scheduleCompletionNotification(at: endDate!)
    }

    private func stop() {
        isRunning = false
        endDate = nil
        secondsRemaining = 0
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus.end"])
    }

    private func tick() {
        guard isRunning, let end = endDate else { return }
        let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
        secondsRemaining = left
        if left <= 0 {
            isRunning = false
            endDate = nil
        }
    }

    private func scheduleCompletionNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "集中タイマー"
        content.body = "時間が経ちました"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        let req = UNNotificationRequest(identifier: "focus.end", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
