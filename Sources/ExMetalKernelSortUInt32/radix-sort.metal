#include <metal_stdlib>
using namespace metal;

kernel void radix_sort(
uint thread_position_in_threadgroup [[thread_position_in_threadgroup]],
uint threadgroup_position_in_grid [[threadgroup_position_in_grid]],
device ulong const * unsorted_array [[buffer(0)]],
device ulong * sorted_array [[buffer(1)]]
)
{
    sorted_array[thread_position_in_threadgroup] = unsorted_array[thread_position_in_threadgroup];
}
