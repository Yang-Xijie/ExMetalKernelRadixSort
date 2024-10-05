import Foundation

public func Sort_Swift(array: inout [ElementOfUInt32KeyAndUInt32Value]) {
    array.sort { $0.value < $1.value }
}
