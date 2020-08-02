// crc32rc.cpp

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

extern "C" uint32_t crc32r(uint32_t, uint8_t *, size_t);

uint32_t crctbl[256];

void gentbl(void)
{
uint32_t crc;
uint32_t b;
uint32_t c;
uint32_t i;
    for(c = 0; c < 0x100; c++){
        crc = c;
        for(i = 0; i < 8; i++){
            b = crc&1;
            crc >>= 1;
// if 1 use crc32, else use crc32c
#if 0
            crc ^= (0 - b) & 0xedb88320;
#else
            crc ^= (0 - b) & 0x82f63b78;
#endif
        }
        crctbl[c] = crc;
    }
}

uint32_t crc32c(uint32_t crc32, uint8_t * bfr, size_t size)
{
uint32_t crc = crc32;
    while(size--)
        crc = (crc >> 8) ^ crctbl[(crc & 0xff)^*bfr++];
    return(crc);
}

uint32_t crc32i(uint32_t crc32, uint8_t * bfr, size_t size){
uint32_t crc = crc32;
    while(size >= 4){
        crc = _mm_crc32_u32 (crc, *(uint32_t *)bfr);
        bfr += 4;
        size -= 4;
    }
    while(size){
        crc = _mm_crc32_u8 (crc, *bfr);
        bfr += 1;
        size -= 1;
    }
    return (crc);
}

#define SIZE (256*1024*1024)

int main(int argc, char**argv)
{
    uint32_t crcc;
    uint32_t crci;
    uint32_t crcr;
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
            crcc = crc32c(0x12345678, bfr, i);
            crcr = crc32r(0x12345678, bfr, i);
            if (crcc != crcr) {
                std::cout << "mismatch" << std::endl;
                break;
            }
        }
        if (i == 4095)
            std::cout << "match" << std::endl;
    }
    QueryPerformanceFrequency(&liQPFrequency);
    dQPFrequency = (double)liQPFrequency.QuadPart;
    timeBeginPeriod(1);                     // set ticker to 1000 hz

    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crcc = crc32c(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;


    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crci = crc32i(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;


    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crcr = crc32r(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;

    timeEndPeriod(1);                       // restore ticker to default
    std::cout << "crcc " << std::hex << std::setw(4) << std::setfill('0') << crcc << std::endl;
    std::cout << "crci " << std::hex << std::setw(4) << std::setfill('0') << crci << std::endl;
    std::cout << "crcr " << std::hex << std::setw(4) << std::setfill('0') << crcr << std::endl;
    delete[] bfr;

    return(0);
}
