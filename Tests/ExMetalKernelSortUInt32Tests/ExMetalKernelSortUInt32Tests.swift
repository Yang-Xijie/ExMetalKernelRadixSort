@testable import ExMetalKernelSortUInt32
import XCTest

final class ExMetalKernelSortUInt32Tests: XCTestCase {
    static func CreateTestArray(N: Int) -> [Element] {
        var array = Array<Element>.init(repeating: .init(key: 0, value: 0), count: N)
        for i in 0 ..< N {
            array[i].key = UInt32(i)
            array[i].value = UInt32.random(in: 0 ..< UInt32.max)
        }
        return array
    }

    static let count_1k = 1024
    static let count_1m = 1024 * 1024
    static let random_array_1k = CreateTestArray(N: count_1k)
    static let sorted_array_1k = random_array_1k.sorted { $0.value < $1.value }
    static let random_array_1m = CreateTestArray(N: count_1m)
    static let sorted_array_1m = random_array_1m.sorted { $0.value < $1.value }

    func Test_Sort_Swift(random_array: [Element]) {
        var array = random_array

        let time = Date.now
        Sort_Swift(array: &array)
        print("Sort_Swift() \(String(format: "%.3f", Date.now.timeIntervalSince(time) * 1000))ms")
    }

    func Test_Sort_RadixSortCPU(random_array: [Element]) {
        var array = random_array

        let time = Date.now
        Sort_RadixSortCPU(array: &array)
        print("Sort_RadixSortCPU() \(String(format: "%.3f", Date.now.timeIntervalSince(time) * 1000))ms")

        print(array[0 ..< 8].map { ($0.key, $0.value) }, "...", array[Self.count_1k - 8 ..< Self.count_1k].map { ($0.key, $0.value) })
    }

    func Test_Sort_RadixSortGPU(random_array: [Element]) {
        let count = random_array.count
        assert(count == 1024)

        let metal_buffer_array = metal_device.makeBuffer(length: MemoryLayout<UInt64>.stride * count)!
        let metal_buffer_input_pointer = metal_buffer_array.contents().bindMemory(to: UInt64.self, capacity: count)
        for i in 0 ..< count {
            metal_buffer_input_pointer[i] = (UInt64(random_array[i].key) << 32) + UInt64(random_array[i].value)
        }

        let time = Date.now
        Sort_RadixSortGPU(array: metal_buffer_array)
        print("Sort_RadixSortGPU() \(String(format: "%.3f", Date.now.timeIntervalSince(time) * 1000))ms")

        var sorted_array: [Element] = .init(repeating: .init(key: 0, value: 0), count: count)
        for i in 0 ..< count {
            sorted_array[i].key = UInt32(metal_buffer_input_pointer[i] >> 32)
            sorted_array[i].value = UInt32(metal_buffer_input_pointer[i] & 0x0000_0000_FFFF_FFFF)
        }

        print(sorted_array[0 ..< 8].map { ($0.key, $0.value) }, "...", sorted_array[Self.count_1k - 8 ..< Self.count_1k].map { ($0.key, $0.value) })
    }

    func test_1k() throws {
        print("count = \(Self.count_1k)")
        print(Self.random_array_1k[0 ..< 8].map { ($0.key, $0.value) }, "...", Self.random_array_1k[Self.count_1k - 8 ..< Self.count_1k].map { ($0.key, $0.value) })
        print(Self.sorted_array_1k[0 ..< 8].map { ($0.key, $0.value) }, "...", Self.sorted_array_1k[Self.count_1k - 8 ..< Self.count_1k].map { ($0.key, $0.value) })

        // MARK: Sort_Swift

        // get duration of Sort_Swift
        Test_Sort_Swift(random_array: Self.random_array_1k)

        // MARK: Sort_RadixSortCPU

        Test_Sort_RadixSortCPU(random_array: Self.random_array_1k)

        // MARK: Sort_RadixSortGPU

        Test_Sort_RadixSortGPU(random_array: Self.random_array_1k)
    }

//    func test_1m() throws {
//        print("count = \(Self.count_1m)")
//        print(Self.random_array_1m[0 ..< 8].map { ($0.key, $0.value) }, "...", Self.random_array_1m[Self.count_1m - 8 ..< Self.count_1m].map { ($0.key, $0.value) })
//        print(Self.sorted_array_1m[0 ..< 8].map { ($0.key, $0.value) }, "...", Self.sorted_array_1m[Self.count_1m - 8 ..< Self.count_1m].map { ($0.key, $0.value) })
//
//        // MARK: Sort_Swift
//
//        // get duration of Sort_Swift
//        Test_Sort_Swift(random_array: Self.random_array_1m)
//
//        // MARK: Sort_RadixSortCPU
//
//        Test_Sort_RadixSortCPU(random_array: Self.random_array_1m)
//    }
}
