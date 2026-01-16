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
    fread(data, 1, *outSize, f);

    fclose(f);

    return data;
}

// Helper to get accessor info
void get_accessor_data(cJSON* gltf, int accessorIndex, uint8_t* binData, float** outData, int* outCount)
{
    cJSON* accessors = cJSON_GetObjectItem(gltf, "accessor");
    cJSON* accessor  = cJSON_GetArrayItem(accessors, accessorIndex);

    int bufferViewIndex = cJSON_GetObjectItem(accessor, "bufferView")->valueint;
    *outCount = cJSON_GetObjectItem(accessor, "count") ->valueint;

    cJSON* bufferViews = cJSON_GetArrayItem(gltf, "bufferViews");
}