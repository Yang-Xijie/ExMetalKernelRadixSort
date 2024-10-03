import Foundation
import MetalKit

let metal_device = MTLCreateSystemDefaultDevice()!
let metal_command_queue = metal_device.makeCommandQueue()!

// MARK: create device, library and function

// https://developer.apple.com/forums/thread/649579?answerId=640250022#640250022
let metal_library = try! metal_device.makeDefaultLibrary(bundle: Bundle.module)
let metal_function = metal_library.makeFunction(name: "radix_sort")!
let metal_compute_pipeline_state = try! metal_device.makeComputePipelineState(function: metal_function)

func Sort_RadixSortGPU(unsorted_array: MTLBuffer, sorted_array: MTLBuffer) {
    for i in 0 ..< 16 {
        Sort_RadixSortGPU(unsorted_array: unsorted_array, sorted_array: sorted_array, radix: 0 + 2 * i)
        Sort_RadixSortGPU(unsorted_array: sorted_array, sorted_array: unsorted_array, radix: 1 + 2 * i)
    }
}

// TODO: change 1024 to variable
/// `radix`: [0,31]
func Sort_RadixSortGPU(unsorted_array: MTLBuffer, sorted_array: MTLBuffer, radix: Int) {
    let metal_command_buffer = metal_command_queue.makeCommandBuffer()!

    let metal_command_encoder = metal_command_buffer.makeComputeCommandEncoder()!
    metal_command_encoder.setComputePipelineState(metal_compute_pipeline_state)

    metal_command_encoder.setBuffer(unsorted_array, offset: 0, index: 0)
    metal_command_encoder.setBuffer(sorted_array, offset: 0, index: 1)
    var radix_bytes = radix
    metal_command_encoder.setBytes(&radix_bytes, length: MemoryLayout<UInt32>.stride, index: 10)

    metal_command_encoder.dispatchThreads(
        .init(
            width: 1024,
            height: 1,
            depth: 1),
        threadsPerThreadgroup: .init(
            width: 1024,
            height: 1,
            depth: 1))

    metal_command_encoder.endEncoding()

    metal_command_buffer.addCompletedHandler { command_buffer in
        print("gpu time: \(String(format: "%.3f", (command_buffer.gpuEndTime - command_buffer.gpuStartTime) * 1000))ms")
    }

    metal_command_buffer.commit()
    metal_command_buffer.waitUntilCompleted()
}
