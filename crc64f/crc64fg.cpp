// crc64fg.cpp = generate constant table

#include <iostream>
#include <iomanip>
#include <stdio.h>

#if 1
#define rk08 0x000000000000001Bull  // crc64 iso
#else
#define rk08 0x42F0E1EBA9EA3693ull  // crc64 ecma
#endif

static uint64_t prk[21] =
    { 0* 0,64* 2,64* 3,64*16,64*17,64* 2,64* 1,
      0* 0, 0* 0,64*14,64*15,64*12,64*13,64*10,
     64*11,64* 8,64* 9,64* 6,64* 7,64* 4,64* 5};

uint64_t grk07(void)
{
uint64_t Nhi = 0x0000000000000001ull;
uint64_t Nlo = 0x0000000000000000ull;
uint64_t Q = 0ull;
    for(size_t i = 0; i < 65; i++){
        Q <<= 1;
        if(Nhi){
            Q |= 1;
            Nlo ^= rk08;
        }
        Nhi = Nlo>>63;
        Nlo <<= 1;
    }
    return Q;                       // 2^128/poly
}

uint64_t grk(uint64_t E){
uint64_t N = 0x8000000000000000ull;
    if (E <= 64)
        return 0ull;
    E -= 63;
    for(size_t i = 0; i < E; i++)
        N = (N<<1)^((0x00ul-(N>>63))&rk08);
    return N;                       // 2^(E)%poly
}

int main(int argc, char**argv)
{
    uint64_t crk[21];
    crk[0] = 0ull;                  // crk[0] not used
    for(size_t i = 1; i < 21; i++)
        crk[i] = grk(prk[i]);
    crk[7] = grk07();               // rk07 = 2^128 / poly
    crk[8] = rk08;                  // rk08 = poly-2^64
    for (size_t i = 1; i < 21; i++)
        printf("rk%02llu    dq      0%016llxh\n", i, crk[i]);
    return(0);
}