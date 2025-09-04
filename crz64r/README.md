Fast reflected 64 bit CRC using avx512 converted from example code from Intel to work with Visual Studio, with comments added to explain what the RK.. constants represent.

reg_sizes.asm - nasm include for crz64ra.asm

crz64ra.asm - nasm assembly code using pclulqdq

crz64rc.cpp - code to test crz64ra.asm

crz64rg.cpp - code to generate the rk.. constants used by crz64fa.asm
