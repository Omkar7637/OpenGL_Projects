#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "cJSON.h"

int main()
{
    FILE* fp = fopen("scene.bin", "rb");
    if(!fp)
    {
        perror("File open failed\n");
        return 1;
    }

    // Get File Size
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    rewind(fp);

    if(size <= 0)
    {
        printf("Empty file\n");
        fclose(fp);
        return 1;
    }

    // Allocate buffer
    unsigned char* buffer = (unsigned char*) malloc(size);
    if(!buffer)
    {
        printf("Memory allocation failed!!");
        fclose(fp);
        return 1;
    }

    // Read File
    fread(buffer, 1, size, fp);

    // Print File Contents (HEX + ASCII)
    printf("File size: %ld bytes\n\n", size);

    for(long i = 0; i < size; i++)
    {
        // print hex
        printf("%02X", buffer[i]);

        // Print ASCII every 16 bytes
        if((i + 1) % 16 == 0)
        {
            printf(" | ");
            for(long j = i - 15; j <= i; j++)
            {
                if(buffer[j] >= 32 && buffer[j] <= 126)
                {
                    printf("%c", buffer[j]);
                }
                else
                {
                    printf(".");
                }
            }
            printf("\n");
        }
    }

    // Clean up
    free(buffer);
    fclose(fp);
    buffer = NULL;
    return (0);
}