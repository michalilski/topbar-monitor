import Foundation
import Testing
@testable import TopbarMonitorCore

@MainActor
struct NetworkMonitorTests {
    @Test func computesRatesAndTotals() {
        var counters = InterfaceCounters(received: 1000, sent: 500)
        let start = Date(timeIntervalSince1970: 0)
        let monitor = NetworkMonitor(reader: { counters }, now: start)
        counters = InterfaceCounters(received: 3000, sent: 1500)
        monitor.sample(at: start.addingTimeInterval(2))
        #expect(monitor.downloadRate == 1000)
        #expect(monitor.uploadRate == 500)
        #expect(monitor.received == 2000)
        #expect(monitor.sent == 1000)
    }

    @Test func ignoresCounterResets() {
        var counters = InterfaceCounters(received: 5000, sent: 5000)
        let start = Date(timeIntervalSince1970: 0)
        let monitor = NetworkMonitor(reader: { counters }, now: start)
        counters = InterfaceCounters(received: 10, sent: 10)
        monitor.sample(at: start.addingTimeInterval(1))
        #expect(monitor.downloadRate == 0)
        #expect(monitor.received == 0)
    }

    @Test func readsRealInterfaces() {
        let counters = InterfaceStats.read()
        #expect(counters.received > 0)
    }
}
