import XCTest
@testable import Doorbell
import EventKit

final class MeetingLinkExtractorTests: XCTestCase {
    private var extractor: MeetingLinkExtractor!
    private var store: EKEventStore!

    override func setUp() {
        super.setUp()
        extractor = MeetingLinkExtractor()
        store = EKEventStore()
    }

    func testExtractsFromEventURL() {
        let event = makeEvent()
        event.url = URL(string: "https://meet.google.com/door-bell")

        let result = extractor.extract(from: event)

        XCTAssertEqual(result?.absoluteString, "https://meet.google.com/door-bell")
    }

    func testExtractsFromLocationWhenURLMissing() {
        let event = makeEvent()
        event.location = "Join here: https://zoom.us/j/123456789"

        let result = extractor.extract(from: event)

        XCTAssertEqual(result?.host, "zoom.us")
    }

    func testExtractsFromNotesWhenURLMissing() {
        let event = makeEvent()
        event.notes = "Details\nLink: https://teams.microsoft.com/l/meetup-join/abcdef"

        let result = extractor.extract(from: event)

        XCTAssertEqual(result?.host, "teams.microsoft.com")
    }

    func testFallsBackToRawURLIfUnknownHost() {
        let event = makeEvent()
        event.url = URL(string: "https://example.internal/room")

        let result = extractor.extract(from: event)

        XCTAssertEqual(result?.absoluteString, "https://example.internal/room")
    }

    // MARK: - Helpers

    private func makeEvent() -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = "Test"
        event.startDate = Date().addingTimeInterval(3600)
        event.endDate = event.startDate.addingTimeInterval(1800)
        return event
    }
}
