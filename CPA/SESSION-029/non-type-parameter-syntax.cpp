void max(int n1, int n2); 

void test()
{
    max(10, 20); 
}
#/////////////////////////////////////

template <typename T1, typename T2> 
void testFunc(T1 m, T2 n)
{

}

void test()
{
    testFunc<int, float>(100, 1.1); 
}
////////////////////////////////////////////
template <typename T, int p> 
void testFunc(T x) 
{
    std::cout << x + p; 
}

void test()
{
    testFunc<int, 10>(200); 
    testFunc<float, 300>(3.3f);
}