// crc16fc.cpp

#include <iostream>
#include <iomanip>
#include <math.h>
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

extern "C" uint16_t crc16f(uint64_t, uint8_t *, size_t);

#define SIZE (256*1024*1024)
// set to 1 to check with c based crc
#define CHK 1

#if CHK

uint16_t crctbl[256];

void gentbl(void)
{
uint16_t crc;
uint16_t b;
uint16_t c;
uint16_t i;
    for(c = 0; c < 0x100; c++){
        crc = c<<8;
        for(i = 0; i < 8; i++){
            b = crc>>15;
            crc <<= 1;
            crc ^= (0-b)&0x8bb7;
        }
        crctbl[c] = crc;
    }
}

uint16_t crc16c(uint64_t crc64, uint8_t * bfr, size_t size)
{
uint16_t crc = (uint16_t)crc64;
    while(size--)
        crc = (crc << 8) ^ crctbl[(crc >> 8)^*bfr++];
    return(crc);
}
#endif

int main(int argc, char**argv)
{
#if CHK
    uint64_t crc0;
#endif
    uint64_t crc1;
    uint8_t * bfr = new (std::nothrow) uint8_t[SIZE];
    if (bfr == 0) {
        std::cout << "not enough memory" << std::endl;
        return 0;
    }
    for(size_t i = 0; i < SIZE/8; i++)
        ((uint64_t *)bfr)[i] = (uint64_t)i;

    QueryPerformanceFrequency(&liQPFrequency);
    dQPFrequency = (double)liQPFrequency.QuadPart;
    timeBeginPeriod(1);                     // set ticker to 1000 hz

#if CHK
    gentbl();
    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crc0 = crc16c(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;
#endif

    Sleep(128);
    QueryPerformanceCounter(&liStartTime);
    crc1 = crc16f(0, bfr, SIZE);
    QueryPerformanceCounter(&liStopTime);
    dStartTime = (double)liStartTime.QuadPart;
    dStopTime = (double)liStopTime.QuadPart;
    dElapsedTime = (dStopTime - dStartTime) / dQPFrequency;
    std::cout << "# of seconds " << dElapsedTime << std::endl;

    timeEndPeriod(1);                       // restore ticker to default
    if (crc0 != crc1) {
        std::cout << "mismatch" << std::endl;
        std::cout << std::hex << std::setw(4) << std::setfill('0') << crc0 << std::endl;
    }
    std::cout << std::hex << std::setw(4) << std::setfill('0') << crc1 << std::endl;
    delete[] bfr;

    return(0);
}