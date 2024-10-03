import Foundation
import MetalKit

let metal_device = MTLCreateSystemDefaultDevice()!
let metal_command_queue = metal_device.makeCommandQueue()!

// MARK: create device, library and function

// https://developer.apple.com/forums/thread/649579?answerId=640250022#640250022
let metal_library = try! metal_device.makeDefaultLibrary(bundle: Bundle.module)

let metal_function_radix_sort_2bit = metal_library.makeFunction(name: "radix_sort_2bit")!
let metal_compute_pipeline_state_radix_sort_2bit = try! metal_device.makeComputePipelineState(function: metal_function_radix_sort_2bit)

// only for 1024 elements
func Sort_RadixSortGPU_1024(array: MTLBuffer) {
    let metal_command_buffer = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder = metal_command_buffer.makeComputeCommandEncoder()!
    metal_command_encoder.setComputePipelineState(metal_compute_pipeline_state_radix_sort_2bit)

    metal_command_encoder.setBuffer(array, offset: 0, index: 0)
    for i_radix_2bit_start in 0 ..< 16 {
        var radix_2bit_start = i_radix_2bit_start * 2
        metal_command_encoder.setBytes(&radix_2bit_start, length: MemoryLayout<UInt32>.stride, index: 10)

        metal_command_encoder.dispatchThreads(
            .init(
                width: 1024,
                height: 1,
                depth: 1),
            threadsPerThreadgroup: .init(
                width: 1024,
                height: 1,
                depth: 1))
    }
    metal_command_encoder.endEncoding()

    metal_command_buffer.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer.commit()
    metal_command_buffer.waitUntilCompleted()
}

let metal_function_scan_initialize = metal_library.makeFunction(name: "scan_initialize")!
let metal_compute_pipeline_state_scan_initialize = try! metal_device.makeComputePipelineState(function: metal_function_scan_initialize)
let metal_function_scan_reduce = metal_library.makeFunction(name: "scan_reduce")!
let metal_compute_pipeline_state_scan_reduce = try! metal_device.makeComputePipelineState(function: metal_function_scan_reduce)
let metal_function_scan_downsweep = metal_library.makeFunction(name: "scan_downsweep")!
let metal_compute_pipeline_state_scan_downsweep = try! metal_device.makeComputePipelineState(function: metal_function_scan_downsweep)
let metal_function_sort_assign = metal_library.makeFunction(name: "sort_assign")!
let metal_compute_pipeline_state_sort_assign = try! metal_device.makeComputePipelineState(function: metal_function_sort_assign)

func Sort_RadixSortGPU_1024x1024(array array_A: MTLBuffer, count: Int) {
    // MARK: create buffers (scan_of_0 and scan_of_1)

    let array_A_pointer = array_A.contents().bindMemory(to: UInt64.self, capacity: count)
    let array_B = metal_device.makeBuffer(length: MemoryLayout<UInt64>.stride * count)!
    let array_B_pointer = array_B.contents().bindMemory(to: UInt64.self, capacity: count)

    let count_pow_of_2 = count / 2 * 2

    let scan_of_0 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count_pow_of_2)!
    let scan_of_0_pointer = scan_of_0.contents().bindMemory(to: UInt32.self, capacity: count_pow_of_2)
    memset(scan_of_0_pointer, 0, count_pow_of_2)
    let scan_of_1 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count_pow_of_2)!
    let scan_of_1_pointer = scan_of_1.contents().bindMemory(to: UInt32.self, capacity: count_pow_of_2)
    memset(scan_of_1_pointer, 0, count_pow_of_2)

    Sort_RadixSortGPU_1024x1024_1bit(array_A: array_A, array_A_pointer: array_A_pointer, array_B: array_B, array_B_pointer: array_B_pointer, count: count,
                                     scan_of_0: scan_of_0, scan_of_0_pointer: scan_of_0_pointer, scan_of_1: scan_of_1, scan_of_1_pointer: scan_of_1_pointer, count_pow_of_2: count_pow_of_2,
                                     radix: 0)
    Sort_RadixSortGPU_1024x1024_1bit(array_A: array_B, array_A_pointer: array_B_pointer, array_B: array_A, array_B_pointer: array_A_pointer, count: count,
                                     scan_of_0: scan_of_0, scan_of_0_pointer: scan_of_0_pointer, scan_of_1: scan_of_1, scan_of_1_pointer: scan_of_1_pointer, count_pow_of_2: count_pow_of_2,
                                     radix: 1)
}

func Sort_RadixSortGPU_1024x1024_1bit(array_A: MTLBuffer, array_A_pointer: UnsafeMutablePointer<UInt64>, array_B: MTLBuffer, array_B_pointer: UnsafeMutablePointer<UInt64>, count: Int,
                                      scan_of_0: MTLBuffer, scan_of_0_pointer: UnsafeMutablePointer<UInt32>, scan_of_1: MTLBuffer, scan_of_1_pointer: UnsafeMutablePointer<UInt32>, count_pow_of_2: Int,
                                      radix: Int)
{
    // MARK: initialize scan_of_0 and scan_of_1

    let metal_command_buffer_scan_initialize = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_scan_initialize = metal_command_buffer_scan_initialize.makeComputeCommandEncoder()!
    metal_command_encoder_scan_initialize.setComputePipelineState(metal_compute_pipeline_state_scan_initialize)

    metal_command_encoder_scan_initialize.setBuffer(array_A, offset: 0, index: 0)
    metal_command_encoder_scan_initialize.setBuffer(scan_of_0, offset: 0, index: 1)
    metal_command_encoder_scan_initialize.setBuffer(scan_of_1, offset: 0, index: 2)

    var radix = radix
    metal_command_encoder_scan_initialize.setBytes(&radix, length: MemoryLayout<UInt32>.stride, index: 10)

    // TODO: change width to count_pow_of_2 and assign 0 to left elements
    metal_command_encoder_scan_initialize.dispatchThreads(
        .init(
            width: count,
            height: 1,
            depth: 1),
        threadsPerThreadgroup: .init(
            width: 1024,
            height: 1,
            depth: 1))

    metal_command_encoder_scan_initialize.endEncoding()

    metal_command_buffer_scan_initialize.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer_scan_initialize.commit()
    metal_command_buffer_scan_initialize.waitUntilCompleted()

    // DEBUG START
    print("DEBUG", terminator: " ")
    for i in 0 ..< 8 {
        print(array_A_pointer[i] & 0x00000000FFFFFFFF, terminator: ", ")
    }
    print("...", terminator: " ")
    for i in 1024 * 1024 - 8 ..< 1024 * 1024 {
        print(array_A_pointer[i] & 0x00000000FFFFFFFF, terminator: ", ")
    }
    print()

    print("DEBUG", terminator: " ")
    for i in 0 ..< 8 {
        print(scan_of_0_pointer[i], terminator: ", ")
    }
    print("...", terminator: " ")
    for i in 1024 * 1024 - 8 ..< 1024 * 1024 {
        print(scan_of_0_pointer[i], terminator: ", ")
    }
    print()

    // DEBUG END

    // MARK: scan_reduce

    let metal_command_buffer_scan_reduce = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_scan_reduce = metal_command_buffer_scan_reduce.makeComputeCommandEncoder()!
    metal_command_encoder_scan_reduce.setComputePipelineState(metal_compute_pipeline_state_scan_reduce)

    metal_command_encoder_scan_reduce.setBuffer(scan_of_0, offset: 0, index: 0)
    metal_command_encoder_scan_reduce.setBuffer(scan_of_1, offset: 0, index: 1)

    var divider = 2
    var threads = count_pow_of_2 / 2
    while threads != 1 {
        metal_command_encoder_scan_reduce.setBytes(&divider, length: MemoryLayout<UInt32>.stride, index: 10)
        metal_command_encoder_scan_reduce.dispatchThreads(
            .init(
                width: threads,
                height: 1,
                depth: 1),
            threadsPerThreadgroup: .init(
                width: 1024,
                height: 1,
                depth: 1))

        divider *= 2
        threads /= 2
    }

    metal_command_encoder_scan_reduce.endEncoding()

    metal_command_buffer_scan_reduce.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer_scan_reduce.commit()
    metal_command_buffer_scan_reduce.waitUntilCompleted()

    // MARK: set last element to zero

    scan_of_0_pointer[count_pow_of_2 - 1] = 0
    scan_of_1_pointer[count_pow_of_2 - 1] = 0

    // MARK: scan_downsweep

    let metal_command_buffer_scan_downsweep = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_scan_downsweep = metal_command_buffer_scan_downsweep.makeComputeCommandEncoder()!
    metal_command_encoder_scan_downsweep.setComputePipelineState(metal_compute_pipeline_state_scan_downsweep)

    metal_command_encoder_scan_downsweep.setBuffer(scan_of_0, offset: 0, index: 0)
    metal_command_encoder_scan_downsweep.setBuffer(scan_of_1, offset: 0, index: 1)

    divider = count_pow_of_2
    threads = 1
    while threads != count_pow_of_2 {
        metal_command_encoder_scan_downsweep.setBytes(&divider, length: MemoryLayout<UInt32>.stride, index: 10)
        metal_command_encoder_scan_downsweep.dispatchThreads(
            .init(
                width: threads,
                height: 1,
                depth: 1),
            threadsPerThreadgroup: .init(
                width: 1024,
                height: 1,
                depth: 1))

        divider /= 2
        threads *= 2
    }

    metal_command_encoder_scan_downsweep.endEncoding()

    metal_command_buffer_scan_downsweep.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer_scan_downsweep.commit()
    metal_command_buffer_scan_downsweep.waitUntilCompleted()

    // MARK: get count_of_0

    var count_of_0 = (array_A_pointer[count - 1] & (1 << radix) == 0) ? (scan_of_0_pointer[count - 1] + 1) : scan_of_0_pointer[count - 1]
    print("DEBUG", "count_of_0 \(count_of_0)")

    // MARK: assign sorted results

    let metal_command_buffer_sort_assign = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_sort_assign = metal_command_buffer_sort_assign.makeComputeCommandEncoder()!
    metal_command_encoder_sort_assign.setComputePipelineState(metal_compute_pipeline_state_sort_assign)

    metal_command_encoder_sort_assign.setBuffer(array_A, offset: 0, index: 0)
    metal_command_encoder_sort_assign.setBuffer(array_B, offset: 0, index: 1)
    metal_command_encoder_sort_assign.setBuffer(scan_of_0, offset: 0, index: 2)
    metal_command_encoder_sort_assign.setBuffer(scan_of_1, offset: 0, index: 3)

    metal_command_encoder_sort_assign.setBytes(&radix, length: MemoryLayout<UInt32>.stride, index: 10)
    metal_command_encoder_sort_assign.setBytes(&count_of_0, length: MemoryLayout<UInt32>.stride, index: 11)

    metal_command_encoder_sort_assign.dispatchThreads(
        .init(
            width: count,
            height: 1,
            depth: 1),
        threadsPerThreadgroup: .init(
            width: 1024,
            height: 1,
            depth: 1))

    metal_command_encoder_sort_assign.endEncoding()

    metal_command_buffer_sort_assign.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer_sort_assign.commit()
    metal_command_buffer_sort_assign.waitUntilCompleted()
}
