import Foundation
import EventKit

final class MeetingLinkExtractor {
    private let detector: NSDataDetector?
    private let knownHosts: [String] = [
        "zoom.us",
        "meet.google.com",
        "teams.microsoft.com",
        "webex.com",
        "slack.com",
        "slack-redir.net",
        "huddle",
        "ringcentral.com"
    ]

    init() {
        detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }

    func extract(from event: EKEvent) -> URL? {
        // Prefer explicit URLs, then location/notes, and finally any link we find as a last resort.
        if let url = conferenceURL(from: event), isMeetingURL(url) {
            return normalized(url)
        }
        if let url = event.url, isMeetingURL(url) {
            return normalized(url)
        }
        if let url = firstMeetingLink(in: event.location) {
            return url
        }
        if let url = firstMeetingLink(in: event.notes) {
            return url
        }
        if let raw = event.url {
            return normalized(raw)
        }
        if let any = firstAnyLink(in: event.location) ?? firstAnyLink(in: event.notes) {
            return normalized(any)
        }
        return nil
    }

    private func firstMeetingLink(in text: String?) -> URL? {
        return firstLink(in: text, allowUnknownHosts: false)
    }

    private func firstAnyLink(in text: String?) -> URL? {
        return firstLink(in: text, allowUnknownHosts: true)
    }

    private func firstLink(in text: String?, allowUnknownHosts: Bool) -> URL? {
        guard let text, !text.isEmpty, let detector else { return nil }
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: (text as NSString).length))
        for match in matches {
            guard let url = match.url else { continue }
            if allowUnknownHosts || isMeetingURL(url) {
                return normalized(url)
            }
        }
        return nil
    }

    private func isMeetingURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return knownHosts.contains(where: { host.contains($0) })
    }

    private func normalized(_ url: URL) -> URL {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var normalized = URLComponents()
        normalized.scheme = components.scheme
        normalized.host = components.host
        normalized.path = components.path
        normalized.query = components.query
        normalized.fragment = components.fragment
        return normalized.url ?? url
    }

    private func conferenceURL(from event: EKEvent) -> URL? {
        // Newer macOS/iOS store video call links in a dedicated property; access via selector to stay compatible.
        let selector = NSSelectorFromString("conferenceURL")
        guard event.responds(to: selector) else { return nil }
        let unmanaged = event.perform(selector)
        return unmanaged?.takeUnretainedValue() as? URL
    }
}
