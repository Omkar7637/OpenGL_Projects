#include <stdio.h> 
#include <stdlib.h> 

void insertion_sort(int* a, size_t N); 
void show(int* a, size_t N, const char* msg); 
void test_sort(void); 

int main(void) 
{
    test_sort(); 
    return (0); 
}

void insertion_sort(int* a, size_t N)
{
    size_t i, j; 
    int key; 

    for(j = 1; j < N; ++j)
    {
        key = a[j]; 
        i = j; 
        while(i > 0 && a[i-1] > key)
        {
            a[i] = a[i-1]; 
            i = i - 1; 
        }

        a[i] = key; 
    }
}

void show(int* a, size_t N, const char* msg)
{
    if(msg)
        puts(msg); 

    for(size_t i = 0; i < N; ++i)
        printf("a[%llu]:%d\n", i, a[i]); 
}

void test_sort(void)
{
    int a[8] = {500, 600, 200, 100, 150, 800, 350, 50}; 

    show(a, 8, "Before sort:"); 
    insertion_sort(a, 8); 
    show(a, 8, "After sort:"); 
}