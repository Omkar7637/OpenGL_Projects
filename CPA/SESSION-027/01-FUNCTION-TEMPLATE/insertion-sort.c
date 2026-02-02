#include <stdio.h> 
#include <stdlib.h> 

void test(void); 
void insertion_sort(int*, int); 
void show(int*, int, const char*); 

int main(void)
{
    test(); 
    return EXIT_SUCCESS; 
}

void test(void) 
{
    void insertion_sort(int*, int); 

    int a1[5] = {500, 400, 300, 200, 100}; 

    show(a1, 5, "BEFORE SORT:"); 
    insertion_sort(a1, 5); 
    show(a1, 5, "AFTER SORT:"); 

    int a2[8] = {800, 700, 600, 500, 400, 300, 200, 100}; 

    show(a2, 8, "BEFORE SORT:"); 
    insertion_sort(a2, 8); 
    show(a2, 8, "AFTER SORT"); 
}

void insertion_sort(int* a, int N)
{
    int i, j; 
    int key; 

    for(j = 1; j < N; ++j)
    {
        key = a[j]; 
        i = j - 1; 
        while(i > -1 && a[i] > key)
        {
            a[i+1] = a[i]; 
            i = i - 1;  
        }

        a[i+1] = key; 
    }
}

void show(int* a, int N, const char* msg)
{
    if(msg)
        puts(msg); 

    for(int i = 0; i < N; ++i)
        printf("a[%d]:%d\n", i, a[i]); 
}

//  T is an ordered data type if one of the following relations 
//  is always true between any two instances t1, t2 of T 
//  t1 < t2, t1=t2, t1 > t2