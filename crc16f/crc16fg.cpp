// crc16fg.cpp = generate constant table

#include <iostream>
#include <iomanip>
#include <stdio.h>

#define rk08 0x000000018bb70000ull  // crc16 polynomial << 16

static uint64_t prk[21] =
    { 0* 0,32* 3,32* 5,32*31,32*33,32* 3,32* 2,
      0* 0, 0* 0,32*27,32*29,32*23,32*25,32*19,
     32*21,32*15,32*17,32*11,32*13,32* 7,32* 9};

uint64_t grk07(void)
{
uint64_t N = 0x100000000ull;
uint64_t Q = 0;
    for(size_t i = 0; i < 33; i++){
        Q <<= 1;
        if(N&0x100000000ull){
            Q |= 1;
            N ^= rk08;
        }
        N <<= 1;
    }
    return Q;
}

uint64_t grk(uint64_t E){
uint64_t N = 0x080000000ull;
    if (E < 32)
        return 0ull;
    E -= 31;
    for(size_t i = 0; i < E; i++){
        N <<= 1;
        if(N&0x100000000ull){
            N ^= rk08;
        }
    }
    return N<<32;
}

int main(int argc, char**argv)
{
    uint64_t crk[21];
    crk[0] = 0ull;           // crk[0] not used
    for(size_t i = 1; i < 21; i++)
        crk[i] = grk(prk[i]);
    crk[7] = grk07();       // rk07 = 2^64 / rk08 (using xor divide)
    crk[8] = rk08;          // rk08 = polynomial
    for (size_t i = 1; i < 21; i++)
        printf("rk%02llu    dq      0%016llxh\n", i, crk[i]);
    return(0);
}