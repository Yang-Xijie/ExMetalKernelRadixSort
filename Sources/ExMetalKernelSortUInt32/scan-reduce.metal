#include <metal_stdlib>
using namespace metal;

/// threads should be pow of 2
kernel void scan_reduce(
uint thread_position_in_grid [[thread_position_in_grid]],
device uint * scan_of_0 [[buffer(0)]],
device uint * scan_of_1 [[buffer(1)]],
device uint & divider [[buffer(10)]]
)
{
    uint right = (thread_position_in_grid + 1) * divider - 1;
    uint left = right - divider / 2;
    scan_of_0[right] += scan_of_0[left];
    scan_of_1[right] += scan_of_1[left];
}
