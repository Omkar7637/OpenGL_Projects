#include<stdio.h>
#include<cuda_runtime.h>

#define N 10

// GPU Kernal (runs on GPU)
__global__ void vectorAdd(int *A, int *B, int *C)
{
    int i = threadIdx.x; // thread ID
    C[i] = A[i] + B[i];
}

int main()
{
    int h_A[N], h_B[N], h_C[N]; // Host (CPU) arrays

    // intialize arrya
    for(int i = 0; i < N; i++)
    {
        h_A[i] = i;
        h_B[i] = i * 10;
    }

    int *d_A, *d_B, *d_C; // Device (GPU) pointers

    // 1) allocate GPU memory
    cudaMalloc((void**)&d_A, N*sizeof(int));
    cudaMalloc((void**)&d_B, N*sizeof(int));
    cudaMalloc((void**)&d_C, N*sizeof(int));

    //2) cpoy CPU -> GPU
    cudaMemcpy(d_A, h_A, )

    

}