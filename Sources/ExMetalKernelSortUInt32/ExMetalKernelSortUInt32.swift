import Foundation

struct Element {
    var key: UInt32
    var value: UInt32
}

func Sort_Swift(array: inout [Element]) {
    array.sort { $0.value < $1.value }
}
