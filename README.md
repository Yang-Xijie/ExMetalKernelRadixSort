# ExMetalKernelRadixSort on UInt32 key-value pairs
 
## Introduction

Metal kernel implementation for simple radix sort.

- input
    - an array with key (UInt32) and value (UInt32) pairs
    - a buffer with keys combined with values (UInt64)
    - notice: up to 4,294,967,295 key-value pairs are supported
- output
    - in-place stable sorted result in the input array

## Usage

**WIP**

## Performance

- test on MacBook Pro with M2 Pro
    - CPU: Total Number of Cores:    10 (6 performance and 4 efficiency)
    - GPU: Total Number of Cores:    16
- input: random arrays

### Release Mode

| Count             | 1k | 10k | 100k | 1m | 10m | 100m | 1b |
| - | - | - | - | - | - | - | - |
| Swift        (ms) | 0.055ms | 0.577ms | 6.941ms | 79.694ms | 939.836ms | 10879.160ms | ... |
| RadixSortGPU (ms) | 23.979ms | 24.656ms | 36.709ms | 71.121ms | 659.600ms | 5349.858ms | ... |

### Debug Mode

| Count             | 1k | 10k | 100k | 1m | 10m | 100m | 1b |
| - | - | - | - | - | - | - | - |
| Swift        (ms) | 0.811 | 34.665 | 132.458 | 975.939 | 11940.425 | 150437.893 | 1161282.611ms |
| RadixSortGPU (ms) | 34.665 | 29.672 | 34.603 | 52.342 | 656.553 | 5370.615 | 0️⃣ |

- 0️⃣: Execution of the command buffer was aborted due to an error during execution. Insufficient Memory (00000008:kIOGPUCommandBufferCallbackErrorOutOfMemory) 78622.588ms no result...

## References

- https://www.youtube.com/watch?v=dPwAA7j-8o4&list=PLAwxTw4SYaPnFKojVQrmyOGFCqHTxfdv2&index=200
- https://www.youtube.com/watch?v=vSs8jkGp9h0&list=PLAwxTw4SYaPnFKojVQrmyOGFCqHTxfdv2&index=201
- https://www.youtube.com/watch?v=K-tNYzw8pm0&list=PLAwxTw4SYaPnFKojVQrmyOGFCqHTxfdv2&index=202
- https://www.youtube.com/watch?v=y52JkxUTg-o&list=PLAwxTw4SYaPnFKojVQrmyOGFCqHTxfdv2&index=203
- https://www.youtube.com/watch?v=iS0S7F2U4-o&list=PLAwxTw4SYaPnFKojVQrmyOGFCqHTxfdv2&index=204
