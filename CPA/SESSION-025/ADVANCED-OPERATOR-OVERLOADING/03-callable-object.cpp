/*
void sort(
    struct Student* pStudent, 
    size_t n, 
    int (*pfn_compare)(struct Student*, struct Student*)
)
{

}

//  Linux C Library function 
void qsort(
    void* arr, 
    size_t nmem, 
    size_t mem_size, 
    int (*pfn)(const void*, const void*)
)
{

}

int pthread_create(pthread_t*, pthread_attr_t*, void*(*)(void*), void*); 
*/

#include <iostream> 
#include <cstdlib> 

int my_add(int, int); 
int my_sub(int, int); 
int my_mul(int, int); 
int my_div(int, int); 

int do_arthimetic(int(*pfn)(int, int), int n1, int n2);

class CallableObject
{
    private: 
        int (*pfn)(int, int); 

    public: 
        CallableObject( int(*_pfn)(int, int) ) : pfn(_pfn)
        {

        } 

        int operator() (int n1, int n2)
        {
            return this->pfn(n1, n2); 
        }
}; 

int main(void)
{
    int p = 100; 
    int q = 7; 
    int result; 

    result = do_arthimetic(my_add, p, q); 
    result = do_arthimetic(my_sub, p, q); 
    result = do_arthimetic(my_mul, p, q); 
    result = do_arthimetic(my_div, p, q); 

    int (*pfn_add)(int, int) = my_add; 
    //  CallableObject addition(pfn_add); 

    CallableObject addition(my_add); 
    CallableObject subtraction(my_sub); 
    CallableObject multiplication(my_mul); 
    CallableObject division(my_div); 

    result = addition(p, q); // CallableObject::operator()(&addition, p, q)
    result = subtraction(p, q); 
    result = multiplication(p, q); 
    result = division(p, q); 

    return (0); 
}

int do_arthimetic(int(*pfn)(int, int), int n1, int n2)
{
    return pfn(n1, n2); 
}

int my_add(int a, int b)
{
    return a+b;
}

int my_sub(int a, int b)
{
    return a-b;
}

int my_mul(int a, int b)
{
    return a*b; 
}

int my_div(int a, int b)
{
    return a/b; 
}