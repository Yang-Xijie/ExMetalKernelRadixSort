#include <metal_stdlib>
using namespace metal;

kernel void radix_sort_assign(
uint thread_position_in_grid [[thread_position_in_grid]],
device ulong * array_A [[buffer(0)]],
device ulong * array_B [[buffer(1)]],
device uint * scan_of_0 [[buffer(2)]],
device uint * scan_of_1 [[buffer(3)]],
device uint & radix [[buffer(10)]],
device uint & count_of_0 [[buffer(11)]]
)
{
    bool is_0 = (uint(array_A[thread_position_in_grid]) & (uint(1) << radix)) == 0;
    if (is_0) {
        array_B[scan_of_0[thread_position_in_grid]] = array_A[thread_position_in_grid];
    } else {
        array_B[count_of_0 + scan_of_1[thread_position_in_grid]] = array_A[thread_position_in_grid];
    }
}
