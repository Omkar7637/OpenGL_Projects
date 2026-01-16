#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"cJSON.h"

// Read entire text file
char* read_text_file(const char* filename)
{
    FILE* f = fopen(filename, "rb");
    if(!f)
    {
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    rewind(f);

    char* data = (char*)malloc(size + 1);
    fread(data, 1, size, f);
    data[size] = '\0';

    fclose(f);

    return data;
}

// Read entire binary file
uint8_t* read_binary_file(const char* filename, size_t* outSize)
{
    FILE* f = fopen(filename, "rb");
    if(!f)
    {
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    *outSize = ftell(f);
    rewind(f);
    uint8_t* data = (uint8_t*)malloc(*outSize);
    fread(data, 1, *outSize)
}