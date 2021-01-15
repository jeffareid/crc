Fast reflected 16 bit CRC converted from example code from Intel to
work with Visual Studio, with comments added to explain what the RK..
constants represent. For reflected operands, pclmulqdq effectively
multiplies the product by 2, which is compensated in the RK.. constants
in crc16ra.asm.

crc16ra.asm - assembly code using pclulqdq

crc16rc.cpp - code to test crc16ra.asm

crc16rg.cpp - code to generate the RK.. constants used by crc16ra.asm
