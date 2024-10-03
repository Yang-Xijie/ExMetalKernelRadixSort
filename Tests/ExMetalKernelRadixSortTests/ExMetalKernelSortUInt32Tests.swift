@testable import ExMetalKernelRadixSort
import XCTest

final class ExMetalKernelSortUInt32Tests: XCTestCase {
    static func CreateTestArray(N: Int) -> [Element] {
        var array = Array<Element>.init(repeating: .init(key: 0, value: 0), count: N)
        for i in 0 ..< N {
            array[i].key = UInt32(i)
//            array[i].value = UInt32.random(in: 0 ..< 2)
//            array[i].value = UInt32.random(in: 0 ..< 4)
            array[i].value = UInt32.random(in: 0 ..< UInt32.max)
        }
        return array
    }

    static let count_1k = 1 * 1024
    static let count_10k = 10 * 1024
    static let count_100k = 100 * 1024
    static let count_1m = 1 * 1024 * 1024
    static let count_10m = 10 * 1024 * 1024
    static let count_100m = 100 * 1024 * 1024
    static let count_1b = 1 * 1024 * 1024 * 1024

    static let random_array_1k = CreateTestArray(N: count_1k)
    static let random_array_10k = CreateTestArray(N: count_10k)
    static let random_array_100k = CreateTestArray(N: count_100k)
    static let random_array_1m = CreateTestArray(N: count_1m)
    static let random_array_10m = CreateTestArray(N: count_10m)
    static let random_array_100m = CreateTestArray(N: count_100m)
    static let random_array_1b = CreateTestArray(N: count_1b)

    func Test_Sort_Swift(random_array: [Element]) {
        let count = random_array.count

        var array = random_array

        let time = Date.now
        Sort_Swift(array: &array)
        print("Sort_Swift() \(String(format: "%.3f", Date.now.timeIntervalSince(time) * 1000))ms")

        print(array[0 ..< 8].map { ($0.key, $0.value) }, "...", array[count - 8 ..< count].map { ($0.key, $0.value) })
    }

    func Test_Sort_RadixSortGPU(random_array: [Element]) {
        let count = random_array.count

        let metal_buffer_array = metal_device.makeBuffer(length: MemoryLayout<UInt64>.stride * count)!
        let metal_buffer_array_pointer = metal_buffer_array.contents().bindMemory(to: UInt64.self, capacity: count)

        for i in 0 ..< count {
            metal_buffer_array_pointer[i] = (UInt64(random_array[i].key) << 32) + UInt64(random_array[i].value)
        }

        let time = Date.now
        Sort_RadixSortGPU(array: metal_buffer_array, count: count)
        print("Sort_RadixSortGPU() \(String(format: "%.3f", Date.now.timeIntervalSince(time) * 1000))ms")

        var array: [Element] = .init(repeating: .init(key: 0, value: 0), count: count)
        for i in 0 ..< count {
            array[i].key = UInt32(metal_buffer_array_pointer[i] >> 32)
            array[i].value = UInt32(metal_buffer_array_pointer[i] & 0x0000_0000_FFFF_FFFF)
        }
        print(array[0 ..< 8].map { ($0.key, $0.value) }, "...", array[count - 8 ..< count].map { ($0.key, $0.value) })
    }

    func test_fdakj() throws {
        print("----")
        Test_Sort_Swift(random_array: Self.random_array_1k)
        Test_Sort_RadixSortGPU(random_array: Self.random_array_1k)
        print("----")

        print("----")
        Test_Sort_Swift(random_array: Self.random_array_10k)
        Test_Sort_RadixSortGPU(random_array: Self.random_array_10k)
        print("----")

        print("----")
        Test_Sort_Swift(random_array: Self.random_array_100k)
        Test_Sort_RadixSortGPU(random_array: Self.random_array_100k)
        print("----")

        print("----")
        Test_Sort_Swift(random_array: Self.random_array_1m)
        Test_Sort_RadixSortGPU(random_array: Self.random_array_1m)
        print("----")

        print("----")
        Test_Sort_Swift(random_array: Self.random_array_10m)
        Test_Sort_RadixSortGPU(random_array: Self.random_array_10m)
        print("----")

//        print("----")
//        Test_Sort_Swift(random_array: Self.random_array_100m)
//        Test_Sort_RadixSortGPU(random_array: Self.random_array_100m)
//        print("----")
//
//        print("----")
//        Test_Sort_Swift(random_array: Self.random_array_1b)
//        Test_Sort_RadixSortGPU(random_array: Self.random_array_1b)
//        print("----")
    }
}
