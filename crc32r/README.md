Fast reflected 32 bit CRC converted from example code from Intel for
Visual Studio, with added comments explaining wht the RK.. constants
represent. For reflected operands, pclmulqdq effectively multiplies
the product by 2, which is compensated in the RK.. constants in
crc32ra.asm.

crc32ra.asm - assembly code using pclulqdq

crc32rc.cpp - code to test crc32ra.asm

crc32rg.cpp - code to generate the RK.. constants used by crc32ra.asm

