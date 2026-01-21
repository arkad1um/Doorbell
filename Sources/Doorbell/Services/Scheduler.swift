import Foundation

@MainActor
protocol SchedulerDelegate: AnyObject {
    func scheduler(_ scheduler: Scheduler, didTrigger meeting: Meeting)
}

@MainActor
final class Scheduler {
    weak var delegate: SchedulerDelegate?

    private var timer: Timer?
    private var scheduledMeeting: Meeting?
    private var leadTime: TimeInterval = 180

    func schedule(meeting: Meeting?, leadTime: TimeInterval) {
        timer?.invalidate()
        self.leadTime = leadTime
        scheduledMeeting = meeting

        guard let meeting else { return }
        let interval = max(1, meeting.startDate.timeIntervalSinceNow - leadTime)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.delegate?.scheduler(self, didTrigger: meeting)
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func snooze(minutes: Int) {
        guard let meeting = scheduledMeeting else { return }
        timer?.invalidate()
        let interval = max(1, TimeInterval(minutes * 60))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.delegate?.scheduler(self, didTrigger: meeting)
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        scheduledMeeting = nil
    }
}
