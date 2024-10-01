import Foundation

func Sort_RadixSortCPU(array: inout [Element]) {
    Sort_RadixSortCPU(array: &array, radix: 0)
}

/// `radix`: [0,31]
func Sort_RadixSortCPU(array: inout [Element], radix: UInt32) {
    let count = array.count
    
    var new_indices: [UInt32] = .init(repeating: 0, count: count)
    
    // MARK: exclusive scan on 0
    
    var index_of_0: UInt32 = 0
    for i in 0 ..< count {
        if array[i].value & (1 << radix) == 0 {
            new_indices[i] = index_of_0
            index_of_0 += 1
        }
    }
    
    let count_of_0 = index_of_0
    
    // MARK: exclusive scan on 1
    
    var index_of_1: UInt32 = count_of_0
    for i in 0 ..< count {
        if array[i].value & (1 << radix) == 1 {
            new_indices[i] = index_of_1
            index_of_1 += 1
        }
    }
    
    // MARK: return sorted array
    
    let original_array: [Element] = array
    for i in 0 ..< count {
        array[Int(new_indices[i])] = original_array[i]
    }
}
