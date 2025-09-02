Fast non-reflected 64 bit CRC using avx512 converted from example code from Intel to work with Visual Studio, with comments added to explain what the RK.. constants represent.

reg_sizes.asm - nasm include for crc64fa.asm

crc64fa.asm - nasm assembly code using pclulqdq

crc64fc.cpp - code to test crc64fa.asm

crc64fg.cpp - code to generate the RK.. constants used by crc64fa.asm
