#include <metal_stdlib>
using namespace metal;

/// threads should be pow of 2
kernel void scan_downsweep(
uint thread_position_in_grid [[thread_position_in_grid]],
device uint * scan_of_0 [[buffer(0)]],
device uint * scan_of_1 [[buffer(1)]],
device uint & divider [[buffer(10)]]
)
{
    uint right = (thread_position_in_grid + 1) * divider - 1;
    uint left = right - divider / 2;
    
    uint right_result_0 = scan_of_0[left] + scan_of_0[right];
    uint left_result_0 = scan_of_0[right];
    scan_of_0[right] = right_result_0;
    scan_of_0[left] = left_result_0;
    
    uint right_result_1 = scan_of_1[left] + scan_of_1[right];
    uint left_result_1 = scan_of_1[right];
    scan_of_1[right] = right_result_1;
    scan_of_1[left] = left_result_1;
}
