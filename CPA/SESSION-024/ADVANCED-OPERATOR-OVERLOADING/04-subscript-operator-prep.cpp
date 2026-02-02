#include <iostream> 
#include <cstdlib> 

class Array 
{
    private: 
        int* pA; 
        int N; 

    public: 
        Array(int _N)
        {
            if(_N <= 0)
            {
                std::cout << "Bad value for array size" << std::endl; 
                exit(EXIT_FAILURE);     // Ideally, throw an exception 
            }

            this->N = _N; 
            this->pA = new int[this->N]; 
        }

        int get(int i) const 
        {
            if(i < 0 || i >= N)
            {
                std::cout << "Array index out of bounds" << std::endl; 
                exit(EXIT_FAILURE);     //  Ideally, throw an exception 
            }

            return this->pA[i]; 
        }

        void set(int i, int val)
        {
            if(i < 0 || i >= N)
            {
                std::cout << "Array index out of bounds" << std::endl; 
                exit(EXIT_FAILURE);     //  Ideally, throw an exception 
            }

            this->pA[i] = val; 
        }

        ~Array()
        {
            delete[] pA; 
            pA = 0; 
        }

        friend std::ostream& operator<<(std::ostream& os, const Array& arrayObject); 
}; 

std::ostream& operator<<(std::ostream& os, const Array& arrayObject)
{
    os << "["; 
    for(int i = 0; i < arrayObject.N; ++i)
        os << arrayObject.pA[i] << ",";
    os << "]" << std::endl; 
    return os;   
}

void testArray(void); 

int main(void)
{
    testArray(); 
    return (0); 
}

void testArray(void)
{
    Array A(8); 

    for(int i = 0; i < 8; ++i)
        A.set(i,  (i + 1) * 10); 

    //  A[i] = (i+1) * 10; 

    for(int i = 0; i < 8; ++i)
    {
        int val = A.get(i);
        //  int val = A[i];  
        std::cout << "Value at index:" << i << " is " << val << std::endl; 
    }

    std::cout << "Alternatively, A:" << A << std::endl; 
}
