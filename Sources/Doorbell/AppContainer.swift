import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let calendarService: CalendarService
    let scheduler: Scheduler
    let appModel: AppModel

    private init() {
        let linkExtractor = MeetingLinkExtractor()
        calendarService = CalendarService(linkExtractor: linkExtractor)
        scheduler = Scheduler()
        appModel = AppModel(calendarService: calendarService, scheduler: scheduler)
    }
}
