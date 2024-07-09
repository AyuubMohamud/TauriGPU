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
#define FIXED_POINT_FRACTIONAL_BITS 15
inline uint16_t float_to_fixed(float input)
{
    return (uint16_t)(round(input * (1 << FIXED_POINT_FRACTIONAL_BITS)));
}
int main() {
    printf("@00000000\n");
    for (int i = 0; i < 512; i++) {
        floatinterpret ratio;
        if (i==0) {
            ratio.y = 0;
        } else {
            ratio.x = sinf((float(i)/float(512))*M_PI);
        }
        printf("%04X\n", float_to_fixed(ratio.x));
    }
}
