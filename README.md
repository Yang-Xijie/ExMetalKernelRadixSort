# ExMetalKernelSortUInt32

- MacBook Pro with M2 Pro
    - CPU: Total Number of Cores:    10 (6 performance and 4 efficiency)
    - GPU: Total Number of Cores:    16

| Count             | 1k | 10k | 100k | 1m | 10m | 100m | 1b |
| - | - | - |
| Swift        (ms) | 0.811 | 34.665 | 132.458 | 975.939 | 11940.425 | 150437.893 |
| RadixSortGPU (ms) | 34.665 | 29.672 | 34.603 | 52.342 | 656.553 | 5370.615 |
