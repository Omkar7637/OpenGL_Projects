/*
    DATA FLOW 

    Mesh
        -> attributes (POSITION, NORMAL, TEXCOORD)
            -> accessor
                -> bufferView
                    -> buffer
                        -> scene.bin (Raw bytes)


              |<----------------|                        
              |                 |    
              |<-> skin --> animation
              |                 |
    Scene -> Node -> mesh -> accessor -> buffer View -> buffer
              |        | 
              |        |-> material-> texture -> image
              |                         |
              |                         |-> sampler
              |-> camera
*/



#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include "cJSON.h"

/* Read entire text file*/
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

/* Read entire binary file */
uint8_t* read_binary_file(const char* filename, size_t* outsize)
{
    FILE* f = fopen(filename, "rb");
    if(!f) 
    {
        return NULL;
    }

    fseek(f, 0, SEEK_END);
    *outsize = ftell(f);
    rewind(f);

    uint8_t* data = (uint8_t*)malloc(*outsize);
    fread(data, 1, *outsize, f);

    fclose(f);
    return data;
}

int main()
{
    ////////////////////////////////
    //// 1. Load glTF JSON file ////
    ////////////////////////////////

    char* gltfText = read_text_file("scene.gltf");
    if(!gltfText)
    {
        printf("Failed to open scene.gltf\n");
        return -1;
    }

    cJSON* gltf = cJSON_Parse(gltfText);
    if(!gltf)
    {
        printf("JSON parse error\n");
        return -1;
    }

    printf("\n Step 1 Done\n");

    ////////////////////////////////////
    //// 2. POSITION accessor index ////
    ////////////////////////////////////

    /*
        scene.gltf (JSON - description)
        "meshes"
            |- "primitives"
                    |- "attributes"
                            |- "POSITION" : 0

                -> Accessor index = 0
    */

    cJSON* meshes                   = cJSON_GetObjectItem(gltf, "meshes");
    cJSON* mesh0                    = cJSON_GetArrayItem(meshes, 0);
    cJSON* primitives               = cJSON_GetObjectItem(mesh0, "primitives");
    cJSON* prim0                    = cJSON_GetArrayItem(primitives, 0);
    
    cJSON* attributes               = cJSON_GetObjectItem(prim0, "attributes");
    int    positionAccessorIndex    = cJSON_GetObjectItem(attributes, "POSITION")->valueint;
    
    printf("\n Step 2 Done\n");

    //////////////////////////
    //// 3. Accessor info ////
    //////////////////////////

    /*
        accessor[]
            [0]                 |<-- POSOTION
                ComponentType = FLOAT (5126)
                type = VEC3
                count = 36
                bufferView = 2

            ---------------------
                      |
            BufferView Index = 2

        Accessor = how to interpret data
    */

    cJSON* accessors                = cJSON_GetObjectItem(gltf, "accessors");
    cJSON* accessor                 = cJSON_GetArrayItem(accessors, positionAccessorIndex);

    int bufferViewIndex             = cJSON_GetObjectItem(accessor, "bufferView")->valueint;
    int count                       = cJSON_GetObjectItem(accessor, "count")->valueint;
    int componentType               = cJSON_GetObjectItem(accessor, "componentType")->valueint;
    const char* type                = cJSON_GetObjectItem(accessor, "type")->valuestring;

    if(componentType != 5126 || strcmp(type, "VEC3") != 0)
    {
        printf("POSITION IS NOT FLOAT VEC3\n");
        return -1;
    }

    printf("\n Step 3 Done\n");

    ////////////////////////////
    //// 4. BufferView Info ////
    ////////////////////////////

    /*
        bufferViews[]
        [2] 
            buffer = 0
            byteoffset = 1024
            bytelength = 432
            vyteStride = (optional)
        ----------------------------
                    |
            buffer index = 0

        bufferView = where in memory
    */

    cJSON* bufferViews              = cJSON_GetObjectItem(gltf, "bufferViews");
    cJSON* bufferView               = cJSON_GetArrayItem(bufferViews, bufferViewIndex);
    
    int bufferIndex                 = cJSON_GetObjectItem(bufferView, "buffer")->valueint;
    int byteOffset                  = 0;
    
    cJSON* offsetItem               = cJSON_GetObjectItem(bufferView, "byteOffset");
    if(offsetItem)
    {
        byteOffset = offsetItem->valueint;
    }

    printf("\n Step 4 Done\n");

    //////////////////////////
    //// 5. Load BIN File ////
    //////////////////////////

    /*
        buffers[]
        [0] 
            uri = "scene.bin"
            bytelength = 4096
        This is the actual binary file on disk
    */

    cJSON* buffers                  = cJSON_GetObjectItem(gltf, "buffers");
    cJSON* buffer                   = cJSON_GetArrayItem(buffers, bufferIndex);

    const char* binFileName         = cJSON_GetObjectItem(buffer, "uri")->valuestring;
    size_t binSize;
    uint8_t*binData                 = read_binary_file(binFileName, &binSize);

    if(!binData)
    {
        printf("Failed to open BIN file\n");
        return -1;
    }

    printf("\n Step 5 Done\n");

    ///////////////////////////////////
    //// 6. Print vertex positions ////
    ///////////////////////////////////

    /*
        scene.bin (raw bytes)
        [ 0 ... 1023 ] other data

        [1024]  X0  Y0  Z0  (vertex data)  
        [1036]  X1  Y1  Z1  (vertex data)
        [1048]  X2  Y2  Y2  (vertex data)

        ....

        VEC3 = 3 floats = 12 bytes

        ----------------------------------------
        binData
        |
        | + byteOffset(1024)
        ▼

        X0 Y0 Z0
    */

    float* vertices = (float*)(binData + byteOffset);

    printf("Vertex count: %d\n\n", count);

    for(int i = 0; i < count; i++)
    {
        float x = vertices[i * 3 + 0];
        float y = vertices[i * 3 + 1];
        float z = vertices[i * 3 + 2];

        printf("Vertex %d: (%f, %f, %f)\n", i, x, y, z);
    }

    printf("\n Step 6 Done\n");

    ////////////////////
    //// 7. Cleanup ////
    ////////////////////

    free(binData);
    cJSON_Delete(gltf);
    free(gltfText);

    return 0;
}