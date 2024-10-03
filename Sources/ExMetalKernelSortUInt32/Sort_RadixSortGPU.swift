import Accelerate
import Foundation
import MetalKit

let metal_device = MTLCreateSystemDefaultDevice()!
let metal_command_queue = metal_device.makeCommandQueue()!

// MARK: - create device, library and function

// https://developer.apple.com/forums/thread/649579?answerId=640250022#640250022
let metal_library = try! metal_device.makeDefaultLibrary(bundle: Bundle.module)

let MetalFunction_scan_initialize = metal_library.makeFunction(name: "radix_sort_scan_initialize")!
let MetalComputePipelineState_scan_initialize = try! metal_device.makeComputePipelineState(function: MetalFunction_scan_initialize)
let MetalFunction_scan_reduce = metal_library.makeFunction(name: "radix_sort_scan_reduce")!
let MetalComputePipelineState_scan_reduce = try! metal_device.makeComputePipelineState(function: MetalFunction_scan_reduce)
let MetalFunction_scan_downsweep = metal_library.makeFunction(name: "radix_sort_scan_downsweep")!
let MetalComputePipelineState_scan_downsweep = try! metal_device.makeComputePipelineState(function: MetalFunction_scan_downsweep)
let MetalFunction_assign = metal_library.makeFunction(name: "radix_sort_assign")!
let MetalComputePipelineState_assign = try! metal_device.makeComputePipelineState(function: MetalFunction_assign)

// MARK: - radix sort for 32 bits

func Sort_RadixSortGPU(array array_A: MTLBuffer, count: Int) {
    // MARK: create buffers (scan_of_0 and scan_of_1)

    let array_A_pointer = array_A.contents().bindMemory(to: UInt64.self, capacity: count)
    let array_B = metal_device.makeBuffer(length: MemoryLayout<UInt64>.stride * count)!
    let array_B_pointer = array_B.contents().bindMemory(to: UInt64.self, capacity: count)

    let count_pow_of_2 = Int(pow(2.0, ceil(log2(Float(count)))))
    print("DEBUG count=\(count)")
    print("DEBUG count_pow_of_2=\(count_pow_of_2)")

    let scan_of_0 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count_pow_of_2)!
    let scan_of_0_pointer = scan_of_0.contents().bindMemory(to: UInt32.self, capacity: count_pow_of_2)
    memset(scan_of_0_pointer, 0, count_pow_of_2)
    let scan_of_1 = metal_device.makeBuffer(length: MemoryLayout<UInt32>.stride * count_pow_of_2)!
    let scan_of_1_pointer = scan_of_1.contents().bindMemory(to: UInt32.self, capacity: count_pow_of_2)
    memset(scan_of_1_pointer, 0, count_pow_of_2)

    for i in 0 ..< 16 {
        Sort_RadixSortGPU_1bit(array_A: array_A, array_A_pointer: array_A_pointer, array_B: array_B, array_B_pointer: array_B_pointer, count: count,
                               scan_of_0: scan_of_0, scan_of_0_pointer: scan_of_0_pointer, scan_of_1: scan_of_1, scan_of_1_pointer: scan_of_1_pointer, count_pow_of_2: count_pow_of_2,
                               radix: i * 2 + 0)
        Sort_RadixSortGPU_1bit(array_A: array_B, array_A_pointer: array_B_pointer, array_B: array_A, array_B_pointer: array_A_pointer, count: count,
                               scan_of_0: scan_of_0, scan_of_0_pointer: scan_of_0_pointer, scan_of_1: scan_of_1, scan_of_1_pointer: scan_of_1_pointer, count_pow_of_2: count_pow_of_2,
                               radix: i * 2 + 1)
    }
}

// MARK: - radix sort for 1 bit

func Sort_RadixSortGPU_1bit(array_A: MTLBuffer, array_A_pointer: UnsafeMutablePointer<UInt64>, array_B: MTLBuffer, array_B_pointer: UnsafeMutablePointer<UInt64>, count: Int,
                            scan_of_0: MTLBuffer, scan_of_0_pointer: UnsafeMutablePointer<UInt32>, scan_of_1: MTLBuffer, scan_of_1_pointer: UnsafeMutablePointer<UInt32>, count_pow_of_2: Int,
                            radix: Int)
{
    // MARK: initialize scan_of_0 and scan_of_1

    let MetalCommandBuffer_scan_initialize = metal_command_queue.makeCommandBuffer()!

    let MetalCommandEncoder_scan_initialize = MetalCommandBuffer_scan_initialize.makeComputeCommandEncoder()!
    MetalCommandEncoder_scan_initialize.setComputePipelineState(MetalComputePipelineState_scan_initialize)

    MetalCommandEncoder_scan_initialize.setBuffer(array_A, offset: 0, index: 0)
    MetalCommandEncoder_scan_initialize.setBuffer(scan_of_0, offset: 0, index: 1)
    MetalCommandEncoder_scan_initialize.setBuffer(scan_of_1, offset: 0, index: 2)

    var radix = radix
    MetalCommandEncoder_scan_initialize.setBytes(&radix, length: MemoryLayout<UInt32>.stride, index: 10)

    // TODO: change width to count_pow_of_2 and assign 0 to left elements
    MetalCommandEncoder_scan_initialize.dispatchThreads(
        .init(
            width: count,
            height: 1,
            depth: 1),
        threadsPerThreadgroup: .init(
            width: 1024,
            height: 1,
            depth: 1))

    MetalCommandEncoder_scan_initialize.endEncoding()

    MetalCommandBuffer_scan_initialize.addCompletedHandler { _ in
//        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    MetalCommandBuffer_scan_initialize.commit()
    MetalCommandBuffer_scan_initialize.waitUntilCompleted()

    // MARK: scan_reduce

    let MetalCommandBuffer_scan_reduce = metal_command_queue.makeCommandBuffer()!

    let MetalCommandEncoder_scan_reduce = MetalCommandBuffer_scan_reduce.makeComputeCommandEncoder()!
    MetalCommandEncoder_scan_reduce.setComputePipelineState(MetalComputePipelineState_scan_reduce)

    MetalCommandEncoder_scan_reduce.setBuffer(scan_of_0, offset: 0, index: 0)
    MetalCommandEncoder_scan_reduce.setBuffer(scan_of_1, offset: 0, index: 1)

    var divider = 2
    var threads = count_pow_of_2 / 2
    while threads != 1 {
        MetalCommandEncoder_scan_reduce.setBytes(&divider, length: MemoryLayout<UInt32>.stride, index: 10)
        MetalCommandEncoder_scan_reduce.dispatchThreads(
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

    MetalCommandEncoder_scan_reduce.endEncoding()

    MetalCommandBuffer_scan_reduce.addCompletedHandler { _ in
//        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    MetalCommandBuffer_scan_reduce.commit()
    MetalCommandBuffer_scan_reduce.waitUntilCompleted()

    // MARK: set last element to zero

    scan_of_0_pointer[count_pow_of_2 - 1] = 0
    scan_of_1_pointer[count_pow_of_2 - 1] = 0

    // MARK: scan_downsweep

    let MetalCommandBuffer_scan_downsweep = metal_command_queue.makeCommandBuffer()!

    let MetalCommandEncoder_scan_downsweep = MetalCommandBuffer_scan_downsweep.makeComputeCommandEncoder()!
    MetalCommandEncoder_scan_downsweep.setComputePipelineState(MetalComputePipelineState_scan_downsweep)

    MetalCommandEncoder_scan_downsweep.setBuffer(scan_of_0, offset: 0, index: 0)
    MetalCommandEncoder_scan_downsweep.setBuffer(scan_of_1, offset: 0, index: 1)

    divider = count_pow_of_2
    threads = 1
    while threads != count_pow_of_2 {
        MetalCommandEncoder_scan_downsweep.setBytes(&divider, length: MemoryLayout<UInt32>.stride, index: 10)
        MetalCommandEncoder_scan_downsweep.dispatchThreads(
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

    MetalCommandEncoder_scan_downsweep.endEncoding()

    MetalCommandBuffer_scan_downsweep.addCompletedHandler { _ in
//        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    MetalCommandBuffer_scan_downsweep.commit()
    MetalCommandBuffer_scan_downsweep.waitUntilCompleted()

    // MARK: get count_of_0

    var count_of_0 = (array_A_pointer[count - 1] & (1 << radix) == 0) ? (scan_of_0_pointer[count - 1] + 1) : scan_of_0_pointer[count - 1]

    // MARK: assign sorted results

    let MetalCommandBuffer_assign = metal_command_queue.makeCommandBuffer()!

    let MetalCommandEncoder_assign = MetalCommandBuffer_assign.makeComputeCommandEncoder()!
    MetalCommandEncoder_assign.setComputePipelineState(MetalComputePipelineState_assign)

    MetalCommandEncoder_assign.setBuffer(array_A, offset: 0, index: 0)
    MetalCommandEncoder_assign.setBuffer(array_B, offset: 0, index: 1)
    MetalCommandEncoder_assign.setBuffer(scan_of_0, offset: 0, index: 2)
    MetalCommandEncoder_assign.setBuffer(scan_of_1, offset: 0, index: 3)

    MetalCommandEncoder_assign.setBytes(&radix, length: MemoryLayout<UInt32>.stride, index: 10)
    MetalCommandEncoder_assign.setBytes(&count_of_0, length: MemoryLayout<UInt32>.stride, index: 11)

    MetalCommandEncoder_assign.dispatchThreads(
        .init(
            width: count,
            height: 1,
            depth: 1),
        threadsPerThreadgroup: .init(
            width: 1024,
            height: 1,
            depth: 1))

    MetalCommandEncoder_assign.endEncoding()

    MetalCommandBuffer_assign.addCompletedHandler { _ in
//        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    MetalCommandBuffer_assign.commit()
    MetalCommandBuffer_assign.waitUntilCompleted()
}
