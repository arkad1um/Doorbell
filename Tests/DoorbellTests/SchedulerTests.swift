import XCTest
@testable import Doorbell

@MainActor
final class SchedulerTests: XCTestCase, SchedulerDelegate {
    private var scheduler: Scheduler!
    private var triggeredMeeting: Meeting?
    private var triggerExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        scheduler = Scheduler()
        scheduler.delegate = self
        triggeredMeeting = nil
        triggerExpectation = nil
    }

    override func tearDown() {
        scheduler.cancel()
        scheduler = nil
        triggerExpectation = nil
        super.tearDown()
    }

    func testSchedulesAndTriggers() async {
        let expectation = expectation(description: "Scheduler triggers meeting")
        triggerExpectation = expectation
        let meeting = Meeting(
            id: "1",
            title: "Call",
            startDate: Date().addingTimeInterval(0.3),
            endDate: Date().addingTimeInterval(600),
            location: nil,
            joinURL: nil,
            calendarName: nil,
            notesSnippet: nil
        )

        scheduler.schedule(meeting: meeting, leadTime: 0)

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(triggeredMeeting?.id, meeting.id)
    }

    // MARK: - SchedulerDelegate

    func scheduler(_ scheduler: Scheduler, didTrigger meeting: Meeting) {
        triggeredMeeting = meeting
        triggerExpectation?.fulfill()
    }
}
