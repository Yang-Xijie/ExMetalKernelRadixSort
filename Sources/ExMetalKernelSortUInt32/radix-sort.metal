#include <metal_stdlib>
using namespace metal;

kernel void radix_sort(
uint thread_position_in_threadgroup [[thread_position_in_threadgroup]],
uint threadgroup_position_in_grid [[threadgroup_position_in_grid]],
device ulong const * unsorted_array [[buffer(0)]],
device uint & radix [[buffer(10)]],
device ulong * sorted_array [[buffer(1)]]
)
{
    // MARK: threadgroup shared memory
    
    threadgroup uint scan_result_of_0[1024];
    threadgroup uint count_of_0 = 0;
    threadgroup uint scan_result_of_1[1024];
    
    scan_result_of_0[thread_position_in_threadgroup] = uint(unsorted_array[thread_position_in_threadgroup] & (ulong(1) << radix)) == 0;
    scan_result_of_1[thread_position_in_threadgroup] = uint(unsorted_array[thread_position_in_threadgroup] & (ulong(1) << radix));
    
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    // MARK: scan with two stages
    
    // exclusive scan: reduce
    for (uint divider = 2; divider != 2048; divider *= 2) {
        if ((thread_position_in_threadgroup + 1) % divider == 0) {
            scan_result_of_0[thread_position_in_threadgroup] += scan_result_of_0[thread_position_in_threadgroup - divider / 2];
            scan_result_of_1[thread_position_in_threadgroup] += scan_result_of_1[thread_position_in_threadgroup - divider / 2];
        }
        metal::threadgroup_barrier(metal::mem_flags::mem_none);
    }
    
    // set the last element 0 (only use one thread to do this)
    if (thread_position_in_threadgroup == 1023) {
        scan_result_of_0[1023] = 0;
        scan_result_of_1[1023] = 0;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    // exclusive scan: downsweep
    for (uint divider = 1024; divider != 1; divider /= 2) {
        if ((thread_position_in_threadgroup + 1) % divider == 0) {
            uint left_for_0 = scan_result_of_0[thread_position_in_threadgroup - divider / 2];
            uint right_for_0 = scan_result_of_0[thread_position_in_threadgroup];
            scan_result_of_0[thread_position_in_threadgroup - divider / 2] = right_for_0;
            scan_result_of_0[thread_position_in_threadgroup] = left_for_0 + right_for_0;
            
            uint left_for_1 = scan_result_of_1[thread_position_in_threadgroup - divider / 2];
            uint right_for_1 = scan_result_of_1[thread_position_in_threadgroup];
            scan_result_of_1[thread_position_in_threadgroup - divider / 2] = right_for_1;
            scan_result_of_1[thread_position_in_threadgroup] = left_for_1 + right_for_1;
        }
        metal::threadgroup_barrier(metal::mem_flags::mem_none);
    }
    
    // deal with the last element to calculate count_of_0 (only use one thread to do this)
    count_of_0 = (uint(unsorted_array[1023] & (ulong(1) << radix)) == 0) ? (scan_result_of_0[1023] + 1) : (scan_result_of_0[1023]);
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    // MARK: assign sorted array with new indices
    
    if (uint(unsorted_array[thread_position_in_threadgroup] & (ulong(1) << radix)) == 0) {
        sorted_array[scan_result_of_0[thread_position_in_threadgroup]] = unsorted_array[thread_position_in_threadgroup];
    } else {
        sorted_array[count_of_0 + scan_result_of_1[thread_position_in_threadgroup]] = unsorted_array[thread_position_in_threadgroup];
    }
}
