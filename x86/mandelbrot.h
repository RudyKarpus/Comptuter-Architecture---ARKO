#ifndef MANDELBROT_SET
#define MANDELBROT_SET

#include <stdint.h>

void mandelbrot(uint8_t* pixelBuffer, long width, long height, long processPower, long setPolong, double centerReal, double centerImag, double zoom);

#endif