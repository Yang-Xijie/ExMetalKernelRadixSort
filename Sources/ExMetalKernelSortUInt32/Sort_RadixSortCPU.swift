import Foundation

func Sort_RadixSortCPU(array: inout [Element]) {
    array.sort { $0.value < $1.value }
}
