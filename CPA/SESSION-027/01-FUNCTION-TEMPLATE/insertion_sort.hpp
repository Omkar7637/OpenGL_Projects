#ifndef _INSERTION_SORT_HPP 
#define _INSERTION_SORT_HPP 

#include <iostream> 

template <typename T> 
void insertion_sort(T* arr, int N)
{
    int i, j; 
    T key; 

    for(j = 1; j < N; ++j)
    {
        key = arr[j]; 

        i = j - 1; 
        while(i > -1 && arr[i] > key)
        {
            arr[i+1] = arr[i]; 
            i = i - 1; 
        }

        arr[i + 1] = key; 
    }
}

template <typename T> 
void show_array(T* arr, int N, const char* msg = 0)
{
    if(msg)
        std::cout << msg << std::endl; 

    for(int i = 0; i < N; ++i)
        std::cout << "arr[" << i << "]:" << arr[i] << std::endl; 
}

#endif 