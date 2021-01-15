Fast reflected 64 bit CRC converted from example code from Intel to
work with Visual Studio, with comments added to explain what the RK..
constants represent. For reflected operands, pclmulqdq effectively
multiplies the product by 2, which is compensated in the RK.. constants
in crc64ra.asm.

crc64ra.asm - assembly code using pclulqdq

crc64rc.cpp - code to test crc64ra.asm

crc64rg.cpp - code to generate the RK.. constants used by crc64ra.asm
