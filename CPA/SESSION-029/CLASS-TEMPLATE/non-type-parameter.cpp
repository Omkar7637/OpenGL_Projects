#include <iostream> 

template <typename T, int p> 
void testFunc(T x) 
{
    std::cout << x + p << std::endl; 
}

/* 
//  Instantiated version of testFunc<int, 10> 
void testFunc(int x)
{
    std::cout << x + 10 << std::endl;   //  p in template def replaced by 10
}

//  Instantiated version of testFunc<float, 20> 
void testFunc(float x)
{
    std::cout << x + 20 << std::endl;   //  p in template def replaced by 20 
}
*/

int main(void) 
{
    testFunc<int, 10>(100);     //  110 
    testFunc<float, 20>(2.2f);  // 22.2 
    return (0); 
}

//  template-id

/* 
    testFunc<int, 10>(100); 

    void testFunc(int x)
    {
        return x + 10; 
    }
    testFunc10 

    push    100 
    call    testFunc10 

    testFunc<int, 20>(100); 

    void testFunc(int x)
    {
        return x + 20; 
    }

    testFunc20

    push    100 
    call    testFunc20 

*/