// crc64fc.cpp

#include <iostream>
#include <iomanip>
#include <math.h>
#include <stdlib.h>
#include <nmmintrin.h>
#include <windows.h>

#pragma comment(lib, "winmm.lib")
typedef LARGE_INTEGER LI64;

static LI64     liQPFrequency;  // cpu counter values
static LI64     liStartTime;
static LI64     liStopTime;
static double   dQPFrequency;
static double   dStartTime;
static double   dStopTime;
static double   dElapsedTime;

#define crc64f crc64_iso_norm_by16_10

extern "C" uint64_t crc64f(uint64_t, uint8_t *, size_t);

uint64_t crctbl[256];

void gentbl(void)
{
uint64_t crc;
uint64_t b;
uint64_t c;
uint64_t i;
    for(c = 0; c < 0x100; c++){
        crc = c<<56;
        for(i = 0; i < 8; i++){
            b = crc>>63;
            crc <<= 1;
#if 1
            crc ^= (0 - b) & 0x000000000000001bull; // crc64 iso
#else
            crc ^= (0 - b) & 0x42f0e1eba9ea3693ull; // crc64 ecma
#endif
        }
        crctbl[c] = crc;
    }
}

uint64_t crc64c(uint64_t crc64, uint8_t * bfr, size_t size)
{
uint64_t crc = crc64;
    while(size--)
        crc = (crc << 8) ^ crctbl[(crc >> 56)^*bfr++];
    return(crc);
}

#define SIZE (256*1024*1024)

int main(int argc, char**argv)
{
    uint64_t crcc;
    uint64_t crcf;
    uint8_t * bfr = new (std::nothrow) uint8_t[SIZE];
    if (bfr == 0) {
        std::cout << "not enough memory" << std::endl;
        return 0;
    }
    gentbl();
    for (size_t i = 0; i < SIZE; i += 8){
        bfr[i+0x00] = (uint8_t)0x01;
        bfr[i+0x01] = (uint8_t)0x02;
        bfr[i+0x02] = (uint8_t)0x04;
        bfr[i+0x03] = (uint8_t)0x08;
        bfr[i+0x04] = (uint8_t)0x10;
        bfr[i+0x05] = (uint8_t)0x20;
        bfr[i+0x06] = (uint8_t)0x40;
        bfr[i+0x07] = (uint8_t)0x80;
    }
    {
        size_t i;
        for (i = 1; i < 4095; i++) {
            crcc = crc64c(0x0ull, bfr, i);
            crcf = crc64f(0x0ull, bfr, i);
//          crcc = crc64c(0x12345678abcdef0ull, bfr, i);
//          crcf = crc64f(0x12345678abcdef0ull, bfr, i);
            if (crcc != crcf) {
                std::cout << "mismatch" << std::endl;
                break;
            }
        }
        if (i == 4095)
            std::cout << "match" << std::endl;
    }

    QueryPerformanceFrequency(&liQPFrequency);
    dQPFrequency = (double)liQPFrequency.QuadPart;
    timeBeginPeriod(256);                   // set ticker to 4 hz

    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crcc = crc64c(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;

    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crcf = crc64f(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;

    timeEndPeriod(256);                     // restore ticker to default
    std::cout << "crcc " << std::hex << std::setw(4) << std::setfill('0') << crcc << std::endl;
    std::cout << "crcf " << std::hex << std::setw(4) << std::setfill('0') << crcf << std::endl;

    delete[] bfr;

    return(0);
}
