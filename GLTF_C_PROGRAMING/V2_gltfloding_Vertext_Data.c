#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"cJSON.h"

// Read entire text file
char* read_text_file(const char* filename)
{
    FILE* f = fopen(filename, "rb")
    if(!f)
    {
        return NULL;
    }
    
}