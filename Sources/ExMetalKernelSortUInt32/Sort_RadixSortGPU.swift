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

func Sort_RadixSortGPU_1024x1024(array array_A: MTLBuffer, count: Int) {
    // MARK: create buffers (scan_of_0 and scan_of_1)

    let array_B = metal_device.makeBuffer(length: MemoryLayout<UInt64>.stride * count)!

    let count_pow_of_2 = count / 2 * 2

    let scan_of_0 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count)!
    let scan_of_0_pointer = scan_of_0.contents().bindMemory(to: UInt32.self, capacity: count)
    let scan_of_1 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count)!
    let scan_of_1_pointer = scan_of_1.contents().bindMemory(to: UInt32.self, capacity: count)

    for i in 0 ..< 16 {
        Sort_RadixSortGPU_1024x1024_2bit(array_A: array_A, array_B: array_B, count: count,
                                         scan_of_0: scan_of_0, scan_of_0_pointer: scan_of_0_pointer, scan_of_1: scan_of_1, scan_of_1_pointer: scan_of_1_pointer, count_pow_of_2: count_pow_of_2,
                                         radix_2bit_start: i * 2)
    }
}

func Sort_RadixSortGPU_1024x1024_2bit(array_A: MTLBuffer, array_B: MTLBuffer, count: Int,
                                      scan_of_0: MTLBuffer, scan_of_0_pointer: UnsafeMutablePointer<UInt32>, scan_of_1: MTLBuffer, scan_of_1_pointer: UnsafeMutablePointer<UInt32>, count_pow_of_2: Int,
                                      radix_2bit_start: Int)
{
    // MARK: initialize scan_of_0 and scan_of_1

    let metal_command_buffer_scan_initialize = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_scan_initialize = metal_command_buffer_scan_initialize.makeComputeCommandEncoder()!
    metal_command_encoder_scan_initialize.setComputePipelineState(metal_compute_pipeline_state_scan_initialize)

    metal_command_encoder_scan_initialize.setBuffer(array_A, offset: 0, index: 0)
    metal_command_encoder_scan_initialize.setBuffer(scan_of_0, offset: 0, index: 1)
    metal_command_encoder_scan_initialize.setBuffer(scan_of_1, offset: 0, index: 2)

    var radix = radix_2bit_start
    metal_command_encoder_scan_initialize.setBytes(&radix, length: MemoryLayout<UInt32>.stride, index: 10)

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

    // MARK: scan_reduce

    let metal_command_buffer_scan_reduce = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder_scan_reduce = metal_command_buffer_scan_reduce.makeComputeCommandEncoder()!
    metal_command_encoder_scan_reduce.setComputePipelineState(metal_compute_pipeline_state_radix_sort_2bit)

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
    
    

    // MARK: get count_of_0

    // MARK: assign sorted results
}
