// crc64rg.cpp = generate reflected constant table

#include <iostream>
#include <iomanip>
#include <stdio.h>

#if 1
#define rk08 0x000000000000001bull  // crc64 iso
#else
#define rk08 0x42F0E1EBA9EA3693ull  // crc64 ecma
#endif

static uint64_t prk[23] =
    { 0* 0,64* 2,64* 3,64*16,64*17,64* 2,64* 1,
      0* 0, 0* 0,64*14,64*15,64*12,64*13,64*10,
     64*11,64* 8,64* 9,64* 6,64* 7,64* 4,64* 5,
     64*32,64*33};

uint64_t btrvrs(uint64_t F)
{
uint64_t R = 0;
    for(size_t i = 0; i < 64; i++){
        R <<= 1;
        R |= (F&1);
        F >>= 1;
    }
    return R;
}


uint64_t grk07(void)
{
uint64_t Nhi = 0x0000000000000001ull;
uint64_t Nlo = 0x0000000000000000ull;
uint64_t Q = 0ull;
    for(size_t i = 0; i < 64; i++){
        Q <<= 1;
        if(Nhi){
            Q |= 1;
            Nlo ^= rk08;
        }
        Nhi = Nlo>>63;
        Nlo <<= 1;
    }
    Q = btrvrs(Q);
    return Q;                       // 2^127 / poly
}

uint64_t grk(uint64_t E){
uint64_t N = 0x8000000000000000ull;
    if (E <= 64)
        return 0ull;
    E -= 64;
    for (size_t i = 0; i < E; i++)
        N = (N << 1) ^ ((0x00ul - (N >> 63))&rk08);
    N = btrvrs(N);
    return N;                       // 2^(E-1)%poly
}

int main(int argc, char**argv)
{
    uint64_t crk[23];
    uint64_t i;
    crk[0] = 0ull;                  // crk[0] not used
    crk[7] = grk07();               // rk07 = 2^127 / poly
    crk[8] = (btrvrs(rk08)<<1)|1;   // rk08 = poly-1
    for(i = 1; i < 23; i++)
        crk[i] = grk(prk[i]);
    for(i = 21; i < 23; i++)
        printf("rk_%01llu    dq      0x%016llx\n", i-20, crk[i]);
    for (i = 1; i < 21; i++)
        printf("rk%02llu    dq      0%016llxh\n", i, crk[i]);
    for (i = 1; i < 3; i++)
        printf("        dq      0x%016llx\n", crk[i]);
    for (i = 1; i < 3; i++)
        printf("        dq      0x%016llx\n", 0x0llu);
    return(0);
}