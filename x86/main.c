

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <stdint.h>
#define SDL_MAIN_HANDLED
#include <SDL.h>
#include "mandelbrot.h"
/*
===============================================================================
                               Save to BMP File
===============================================================================
*/

void saveBMP(const char *filename, int width, int height, unsigned char *buffer) {
    FILE *f;
    unsigned char *img = NULL;
    int filesize = 54 + 4 * width * height;

    img = (unsigned char *)malloc(4 * width * height);
    if (img == NULL) {
        printf("Failed to allocate memory for BMP\n");
        return;
    }

    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            int x = i;
            int y = (height - 1) - j;
            img[(x + y * width) * 4 + 2] = buffer[(i + j * width) * 4 + 0];
            img[(x + y * width) * 4 + 1] = buffer[(i + j * width) * 4 + 1];
            img[(x + y * width) * 4 + 0] = buffer[(i + j * width) * 4 + 2];
            img[(x + y * width) * 4 + 3] = buffer[(i + j * width) * 4 + 3];
        }
    }

    unsigned char bmpfileheader[14] = {
        'B', 'M',  filesize & 0xFF, (filesize >> 8) & 0xFF, (filesize >> 16) & 0xFF, (filesize >> 24) & 0xFF,
        0, 0, 0, 0, 54, 0, 0, 0
    };
    unsigned char bmpinfoheader[40] = {
        40, 0, 0, 0,  width & 0xFF, (width >> 8) & 0xFF, (width >> 16) & 0xFF, (width >> 24) & 0xFF,
        height & 0xFF, (height >> 8) & 0xFF, (height >> 16) & 0xFF, (height >> 24) & 0xFF,
        1, 0, 32, 0
    };

    f = fopen(filename, "wb");
    if (f == NULL) {
        printf("Failed to open BMP file\n");
        free(img);
        return;
    }
    fwrite(bmpfileheader, 1, 14, f);
    fwrite(bmpinfoheader, 1, 40, f);
    fwrite(img, 1, 4 * width * height, f);
    fclose(f);
    free(img);
}

/*
===============================================================================
                                    Main
===============================================================================
*/

int main(int argc, char* argv[])
{
    // Default values
    long WIDTH = 800;
    long HEIGHT = 600;
    long processPower = 25;
    long setPoint = 10;
    const char* outputFilename = "mandelbrot.bmp";

    // Display help message if required
    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        printf("Usage: ./mandelbrot [width] [height] [process power] [set point] [output file name]\n");
        printf("If no arguments are provided, default values will be used:\n");
        printf("Width: %ld, Height: %ld, Process Power: %ld, Set Point: %ld, Output-File Name: %s\n",
                WIDTH, HEIGHT, processPower, setPoint, outputFilename);
        return 0;
    }

    // Parse command line arguments
    if (argc > 1) {
        WIDTH = strtol(argv[1], NULL, 10);
    }
    if (argc > 2) {
        HEIGHT = strtol(argv[2], NULL, 10);
    }
    if (argc > 3) {
        processPower = strtol(argv[3], NULL, 10);
    }
    if (argc > 4) {
        setPoint = strtol(argv[4], NULL, 10);
    }
    if (argc > 5) {
        outputFilename = argv[5];
    }

    // Initialize SDL
    if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
        printf("SDL initialization failed: %s\n", SDL_GetError());
        return -1;
    }

    // Window creation
    SDL_Window *window = SDL_CreateWindow("Mandelbrot Set", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, SDL_WINDOW_ALLOW_HIGHDPI);
    if (window == NULL) {
        printf("Failed to create SDL window: %s\n", SDL_GetError());
        SDL_Quit();
        return -1;
    }
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Failed to create SDL renderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    // Mandelbrot RGBA buffer
    uint8_t* buf = (uint8_t*)malloc(WIDTH * HEIGHT * 4 * sizeof(uint8_t*));
    if (buf == NULL) {
        printf("Failed to allocate memory for pixel buffer\n");
        return -1;
    }

    double centerReal = -0.5;
    double centerImag = 0.0;
    double zoom = 1.0;

    // Generate Mandelbrot set
    mandelbrot(buf, WIDTH, HEIGHT, processPower, setPoint, centerReal, centerImag, zoom);

    // Save to BMP file if output file name provided
    if (argc > 5) saveBMP("mandelbrot.bmp", WIDTH, HEIGHT, buf);

    SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(buf, WIDTH, HEIGHT, 32, WIDTH * 4, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);

    int quit = 0;
    SDL_Event e;
    while (!quit) {
        int needRedraw = 0;
        while (SDL_PollEvent(&e) != 0)
        {
            if (e.type == SDL_QUIT)
            {
                quit = 1;
            }
            else if (e.type == SDL_MOUSEWHEEL)
            {
                int mouseX, mouseY;
                SDL_GetMouseState(&mouseX, &mouseY);
                double beforeZoomRe = ((double)mouseX - WIDTH / 2.0) * 4.0 / (WIDTH * zoom) + centerReal;
                double beforeZoomIm = ((double)mouseY - HEIGHT / 2.0) * 4.0 / (HEIGHT * zoom) + centerImag;

                if (e.wheel.y > 0)
                {
                    zoom *= 1.1;
                }
                else if (e.wheel.y < 0)
                {
                    zoom /= 1.1;
                }
                double afterZoomRe = ((double)mouseX - WIDTH / 2.0) * 4.0 / (WIDTH * zoom) + centerReal;
                double afterZoomIm = ((double)mouseY - HEIGHT / 2.0) * 4.0 / (HEIGHT * zoom) + centerImag;

                centerReal += (beforeZoomRe - afterZoomRe);
                centerImag += (beforeZoomIm - afterZoomIm);
                needRedraw = 1;
            }
            else if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == SDL_BUTTON_LEFT)
            {
                int mouseX = e.button.x;
                int mouseY = e.button.y;

                centerReal += ((double) mouseX - WIDTH / 2.0) * 4.0 / (WIDTH * zoom);
                centerImag += ((double) mouseY - HEIGHT / 2.0) * 4.0 / (HEIGHT * zoom);
                needRedraw = 1;
            }
        }
        if (needRedraw)
        {
            //mandelbrot(buf, WIDTH, HEIGHT, processPower, setPoint, centerReal, centerImag, zoom);
            SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(buf, WIDTH, HEIGHT, 32, WIDTH * 4, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
            SDL_DestroyTexture(texture);
            texture = SDL_CreateTextureFromSurface(renderer, surface);
            SDL_FreeSurface(surface);
        }
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyTexture(texture);
    free(buf);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}

// ============================================================================












/*
#include <stdio.h>
#include <stdbool.h>
#include <SDL.h>

#define STEP 10
#define DEFAULT_WIDTH 640
#define DEFAULT_HEIGHT 480


void * vertical;
void * horizontal;

#undef main

int main() {
   if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return -1;
    }

    // Create window
    SDL_Window* window = SDL_CreateWindow("SDL Tutorial", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, DEFAULT_WIDTH, DEFAULT_HEIGHT, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return -1;
    }
    horizontal = malloc(STEP * DEFAULT_WIDTH * sizeof(unsigned int));
    vertical = malloc(STEP * DEFAULT_HEIGHT * sizeof(unsigned int));
    // Get window surface
    SDL_Surface* screenSurface = SDL_GetWindowSurface(window);

    // Main loop flag
    bool quit = false;

    // Event handler
    SDL_Event e;

    // While application is running
    while (!quit) {
        // Handle events on queue
        while (SDL_PollEvent(&e) != 0) {
            // User requests quit
            if (e.type == SDL_QUIT) {
                quit = true;
            }
            // User presses a key
            else if (e.type == SDL_KEYDOWN) {
                // Select surfaces based on key press
                switch (e.key.keysym.sym) {
                    case SDLK_UP:
                        SDL_SetWindowTitle(window, "Up Arrow Pressed");
                        break;
                    case SDLK_DOWN:
                        SDL_SetWindowTitle(window, "Down Arrow Pressed");
                        break;
                    case SDLK_LEFT:
                        SDL_SetWindowTitle(window, "Left Arrow Pressed");
                        break;
                    case SDLK_RIGHT:
                        SDL_SetWindowTitle(window, "Right Arrow Pressed");
                        break;
                    case SDLK_ESCAPE:
                        quit = true;
                        break;

                }
            }
            // User clicks the mouse
            else if (e.type == SDL_MOUSEBUTTONDOWN) {
                int x, y;
                SDL_GetMouseState(&x, &y);
                char title[256];
                snprintf(title, sizeof(title), "Mouse Button Pressed at (%d, %d)", x, y);
                SDL_SetWindowTitle(window, title);
            }
            else if (e.type == SDL_MOUSEWHEEL) {
                if (e.wheel.y > 0) {
                    SDL_SetWindowTitle(window, "Zoomed in");
                } else if (e.wheel.y < 0) {
                    SDL_SetWindowTitle(window, "Zoomed out");
                }
            }
        }

        // Fill the surface white
        SDL_FillRect(screenSurface, NULL, SDL_MapRGB(screenSurface->format, 0xFF, 0xFF, 0xFF));

        // Update the surface
        SDL_UpdateWindowSurface(window);
    }

    // Destroy window
    SDL_DestroyWindow(window);

    // Quit SDL subsystems
    SDL_Quit();

    return 0;
}
*/