/*
MIT License

Copyright (c) 2024 Ayuub Mohamud

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <cmath>
#include <cstdint>
#include <iostream>

union floatinterpret {
    float x;
    int y;
};
int main() {
    printf("@00000000\n");
    for (int i = 0; i < 1024; i++) {
        floatinterpret ratio;
        if (i==0) {
            ratio.y = 0b01000000011111111111111111111111;
        } else {
            ratio.x = 1.0f/sqrtf((float)(i+1024)/1024);
        }
        ratio.y &= 0x007FFF00;
        ratio.y >>= 8;
        //ratio.y |= 0x00008000;
        printf("%04X\n", ratio.y);
    }
    for (int i = 0; i < 2048; i++) {
        floatinterpret ratio;
        if (i&0x00000001) {
            ratio.x = 1.0f/sqrtf((float)(i+2048)/(float)1024);        
            ratio.y &= 0x007FFF00;
            ratio.y >>= 8;
            //ratio.y |= 0x00008000;
            printf("%04X\n", ratio.y);
        }
    }
}