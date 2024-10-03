#include <metal_stdlib>
using namespace metal;

kernel void radix_sort_2bit(
uint thread_position_in_threadgroup [[thread_position_in_threadgroup]],
uint threadgroup_position_in_grid [[threadgroup_position_in_grid]],
device ulong * array [[buffer(0)]],
device uint & radix_2bit_start [[buffer(10)]]
)
{
    // MARK: threadgroup shared memory

    threadgroup uint scan_result_of_0[1024];
    threadgroup uint count_of_0 = 0;
    threadgroup uint scan_result_of_1[1024];
    
    threadgroup ulong array_mid[1024];
    
    // MARK: - first bit
    
    // MARK: initialize scan_result

    scan_result_of_0[thread_position_in_threadgroup] = uint(array[thread_position_in_threadgroup] & (ulong(1) << radix_2bit_start)) == 0;
    scan_result_of_1[thread_position_in_threadgroup] = uint(array[thread_position_in_threadgroup] & (ulong(1) << radix_2bit_start)) == (uint(1) << radix_2bit_start);
    
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
    count_of_0 = (uint(array[1023] & (ulong(1) << radix_2bit_start)) == 0) ? (scan_result_of_0[1023] + 1) : (scan_result_of_0[1023]);
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    // MARK: assign sorted array with new indices
    
    if (uint(array[thread_position_in_threadgroup] & (ulong(1) << radix_2bit_start)) == 0) {
        array_mid[scan_result_of_0[thread_position_in_threadgroup]] = array[thread_position_in_threadgroup];
    } else {
        array_mid[count_of_0 + scan_result_of_1[thread_position_in_threadgroup]] = array[thread_position_in_threadgroup];
    }
    
    // MARK: - second bit
    
    // MARK: initialize scan_result

    scan_result_of_0[thread_position_in_threadgroup] = uint(array_mid[thread_position_in_threadgroup] & (ulong(1) << (radix_2bit_start + 1))) == 0;
    scan_result_of_1[thread_position_in_threadgroup] = uint(array_mid[thread_position_in_threadgroup] & (ulong(1) << (radix_2bit_start + 1))) == (uint(1) << (radix_2bit_start + 1));
    
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
    count_of_0 = (uint(array_mid[1023] & (ulong(1) << (radix_2bit_start + 1))) == 0) ? (scan_result_of_0[1023] + 1) : (scan_result_of_0[1023]);
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    // MARK: assign sorted array_mid with new indices
    
    if (uint(array_mid[thread_position_in_threadgroup] & (ulong(1) << (radix_2bit_start + 1))) == 0) {
        array[scan_result_of_0[thread_position_in_threadgroup]] = array_mid[thread_position_in_threadgroup];
    } else {
        array[count_of_0 + scan_result_of_1[thread_position_in_threadgroup]] = array_mid[thread_position_in_threadgroup];
    }
}
