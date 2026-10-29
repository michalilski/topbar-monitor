import Foundation
import Testing
@testable import TopbarMonitorCore

struct ParserTests {
    @Test func parsesClaudeUsage() throws {
        let json = """
        {"five_hour": {"utilization": 6.0, "resets_at": "2026-10-15T17:00:00.367996+00:00"},
         "seven_day": {"utilization": 43.0, "resets_at": "2026-10-16T13:00:00+00:00"}}
        """
        let snapshot = try ClaudeUsageParser.parse(Data(json.utf8))
        #expect(snapshot.session?.percent == 6)
        #expect(snapshot.weekly?.percent == 43)
        #expect(snapshot.session?.resetsAt != nil)
        #expect(snapshot.weekly?.resetsAt == ISODate.parse("2026-10-16T13:00:00Z"))
    }

    @Test func parsesChatGPTUsage() throws {
        let json = """
        {"plan_type": "plus", "rate_limit": {
          "primary_window": {"used_percent": 12, "reset_after_seconds": 600},
          "secondary_window": {"used_percent": 30, "reset_at": 1800000000}}}
        """
        let now = Date(timeIntervalSince1970: 0)
        let snapshot = try ChatGPTUsageParser.parse(Data(json.utf8), now: now)
        #expect(snapshot.session == UsageWindow(percent: 12, resetsAt: Date(timeIntervalSince1970: 600)))
        #expect(snapshot.weekly == UsageWindow(percent: 30, resetsAt: Date(timeIntervalSince1970: 1_800_000_000)))
    }

    @Test func rejectsMalformedPayload() {
        #expect(throws: UsageError.invalidResponse) { try ClaudeUsageParser.parse(Data("[]".utf8)) }
    }
}
