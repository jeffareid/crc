Fast non-reflected 64 bit CRC using avx512 converted from example code from Intel to work with Visual Studio, with comments added to explain what the RK.. constants represent.

reg_sizes.asm - nasm include for crz64fa.asm

crz64fa.asm - nasm assembly code using pclulqdq

crz64fc.cpp - code to test crc64ra.asm

crz64fg.cpp - code to generate the rk.. constants used by crz64fa.asm
