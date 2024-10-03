import Foundation

func Sort_Swift(array: inout [Element]) {
    array.sort { $0.value < $1.value }
}
