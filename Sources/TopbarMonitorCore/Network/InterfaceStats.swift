import Darwin

public struct InterfaceCounters: Equatable, Sendable {
    public let received: UInt64
    public let sent: UInt64

    public static let zero = InterfaceCounters(received: 0, sent: 0)
}

/// Reads 64-bit byte counters of physical (`en*`) interfaces via `NET_RT_IFLIST2`.
public enum InterfaceStats {
    public static func read() -> InterfaceCounters {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, 6, nil, &length, nil, 0) == 0 else { return .zero }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, 6, &buffer, &length, nil, 0) == 0 else { return .zero }
        return buffer.withUnsafeBytes { sum(UnsafeRawBufferPointer(rebasing: $0.prefix(length))) }
    }

    private static func sum(_ raw: UnsafeRawBufferPointer) -> InterfaceCounters {
        var received: UInt64 = 0
        var sent: UInt64 = 0
        var offset = 0
        while offset + MemoryLayout<if_msghdr>.size <= raw.count {
            let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
            if Int32(header.ifm_type) == RTM_IFINFO2 {
                let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                if isPhysical(index: message.ifm_index) {
                    received += message.ifm_data.ifi_ibytes
                    sent += message.ifm_data.ifi_obytes
                }
            }
            guard header.ifm_msglen > 0 else { break }
            offset += Int(header.ifm_msglen)
        }
        return InterfaceCounters(received: received, sent: sent)
    }

    private static func isPhysical(index: UInt16) -> Bool {
        var name = [CChar](repeating: 0, count: Int(IF_NAMESIZE))
        guard if_indextoname(UInt32(index), &name) != nil else { return false }
        return String(cString: name).hasPrefix("en")
    }
}
