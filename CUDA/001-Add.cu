#include <stdio.h>
#include <cuda_runtime.h>

#define N 10

// GPU Kernel (runs on GPU)
__global__ void vectorAdd(int *A, int *B, int *C)
{
    int i = threadIdx.x;   // thread ID
    C[i] = A[i] + B[i];
}

int main()
{
    int h_A[N], h_B[N], h_C[N];  // Host (CPU) arrays

    // initialize arrays
    for(int i=0;i<N;i++){
        h_A[i] = i;
        h_B[i] = i*10;
    }

    int *d_A, *d_B, *d_C;   // Device (GPU) pointers

    // 1) allocate GPU memory
    cudaMalloc((void**)&d_A, N*sizeof(int));
    cudaMalloc((void**)&d_B, N*sizeof(int));
    cudaMalloc((void**)&d_C, N*sizeof(int));

    // 2) copy CPU -> GPU
    cudaMemcpy(d_A, h_A, N*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, N*sizeof(int), cudaMemcpyHostToDevice);

    // 3) launch kernel
    vectorAdd<<<1, N>>>(d_A, d_B, d_C);

    
    // ADD THIS
    cudaDeviceSynchronize();

    // 4) copy GPU -> CPU
    cudaMemcpy(h_C, d_C, N*sizeof(int), cudaMemcpyDeviceToHost);

    // print result
    printf("Result:\n");
    for(int i=0;i<N;i++)
        printf("%d + %d = %d\n", h_A[i], h_B[i], h_C[i]);

    // 5) free GPU memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    return 0;
}
