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
    threadgroup uint threadgroup_memory[1024];
    threadgroup_memory[thread_position_in_threadgroup] = unsorted_array[thread_position_in_threadgroup] & 0x00000000FFFFFFFF;
    metal::threadgroup_barrier(metal::mem_flags::mem_none);
    
    for (uint divider = 2; divider != 2048; divider *= 2) {
        if ((thread_position_in_threadgroup + 1) % divider == 0) {
            threadgroup_memory[thread_position_in_threadgroup] += threadgroup_memory[thread_position_in_threadgroup - divider / 2];
        }
        metal::threadgroup_barrier(metal::mem_flags::mem_none);
    }

    sorted_array[thread_position_in_threadgroup] = threadgroup_memory[thread_position_in_threadgroup];
}
