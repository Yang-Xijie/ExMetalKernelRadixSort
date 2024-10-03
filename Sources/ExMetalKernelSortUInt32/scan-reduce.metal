#include <metal_stdlib>
using namespace metal;

/// threads should be pow of 2
kernel void scan_reduce(
uint thread_position_in_grid [[thread_position_in_grid]],
device ulong * array_A [[buffer(0)]],
device ulong * array_B [[buffer(1)]],
device uint * scan_of_0 [[buffer(2)]],
device uint * scan_of_1 [[buffer(3)]],
device uint & divider [[buffer(10)]]
)
{
    
}
