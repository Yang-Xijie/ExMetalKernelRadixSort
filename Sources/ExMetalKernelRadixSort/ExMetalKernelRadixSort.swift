import Foundation

public struct Element {
    public var key: UInt32
    public var value: UInt32

    public init(key: UInt32, value: UInt32) {
        self.key = key
        self.value = value
    }
}
