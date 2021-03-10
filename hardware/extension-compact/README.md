Work in progress. Untested. On a back burner for now.

Other than compactness, this board is not substantially better than the [retro version](../extension-retro).
An idea would be to leverage all the unused macrocells in the CPLD to accelerate SPI transactions. We could read/write SD cards at 10Mbits/second instead of just 1Mbit/second with the current `SYS_SpiExchangeBytes_v4_134`. But this is of secondary importance compared to making the OS software to read/write SD cards reliably.
