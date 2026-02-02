#ifndef _ARRAY_H 
#define _ARRAY_H 

#include <iostream> 
#include <stdexcept> 

typedef long long ssize_t; 

template <typename T, ssize_t N> 
class Array 
{
    private: 
        T*  p_array; 
    public: 
        Array()
        {
            if(N <= 0)
                throw std::runtime_error("Array length cannot be zero");             
            p_array = new T[N]; 
        }

        T& operator[](std::size_t index)
        {
            if(index < 0 || index >= N)
                throw std::runtime_error("Array index out of range"); 
            return *(p_array + index); 
        }

        std::size_t size() const 
        {
            return N; 
        }

        bool find(T const& searchObject) const 
        {
            for(std::size_t i = 0; i < N; ++i)
                if(p_array[i] == searchObject)
                    return true; 
            return false; 
        }

        void sort()
        {
            ssize_t i, j; 
            T key; 

            for(j = 1; j < N; ++j)
            {
                key = p_array[j]; 
                for(i = j - 1; i > -1 && p_array[i] > key; --i)
                    p_array[i+1] = p_array[i]; 
                p_array[i+1] = key; 
            }
        }

        class iterator 
        {
            private: 
                T* ptr; 
            public: 
                iterator(T* _ptr = 0) : ptr(_ptr)
                {
                }

                T& operator*() 
                {
                    return *ptr; 
                }

                bool operator==(const iterator &other) 
                {
                    return ptr == other.ptr; 
                }

                bool operator!=(const iterator& other)
                {
                    return ptr != other.ptr; 
                }

                iterator& operator++() 
                {
                    ptr += 1; 
                    return *this; 
                }

                iterator& operator--() 
                {
                    ptr -= 1; 
                    return *this; 
                }

                iterator operator++(int)
                {
                    iterator tmp(ptr); 
                    ptr += 1; 
                    return tmp; 
                }

                iterator operator--(int)
                {
                    iterator tmp(ptr); 
                    ptr -= 1; 
                    return tmp; 
                }
        }; 

        iterator begin() 
        {
            return iterator(p_array); 
        }

        iterator end() 
        {
            return iterator(p_array + N); 
        }
};

#endif // _ARRAY_H