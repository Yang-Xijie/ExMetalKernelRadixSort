#include <metal_stdlib>
using namespace metal;

/// any threads
kernel void scan_initialize(
uint thread_position_in_grid [[thread_position_in_grid]],
device ulong * array [[buffer(0)]],
device uint * scan_of_0 [[buffer(1)]],
device uint * scan_of_1 [[buffer(2)]],
device uint & radix [[buffer(10)]]
)
{
    uint value = uint(array[thread_position_in_grid]);
    uint t = uint(1) << radix;
    uint and_result = value & t;
    
    scan_of_0[thread_position_in_grid] = (and_result == uint(0));
    scan_of_1[thread_position_in_grid] = (and_result == t);
}
