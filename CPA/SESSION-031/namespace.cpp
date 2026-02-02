class A 
{
    int n; 
    public: 
        class B 
        {
            void f()
            {
                std::cout << n << std::endl;
            }
        }; 
}; 

 class B 
        {
            void f()
            {
                std::cout << n << std::endl;
            }
        }; 

void test()
{
    A::B objB; 

    A ObjA;     // A is an unqualified name 

    A::B objB;  //  A::B -> qualified name 
}

Mr. Yogeshwar Shukla

Dr. Yogeshwar Shukla

Yogeshwar Shukla -> Unqualified Name 

Dr. Yogeshwar Shukla -> Qualified Name 

namespace std 
{

    class vector 
    {
        class iterator 
        {

        }; 
    }; 

    class vector_iterator 
    {

    }; 

    class list 
    {
        class iterator 
        {

        }; 
    }; 

    

    class deque 
    {
        class iterator 
        {

        };
    }; 

   
}

#include <vector> 

namespace std 
{ 
    class vector 
    {
        class iterator 
        {

        }; 
    }; 
}

#include <list> 

namespace std 
{
    class list 
    {

    }; 


}

HEADER cpa_list

namespace cpa 
{
    namespace dsa 
    {
        template <typename T> 
        class vector 
        {
            public: 
                class iterator 
                {

                }; 
        }; 
    }; 
}; 

HEADER cpa_bst 
namespace cpa 
{
    namespace dsa 
    {
        template <typename T> 
        class bst 
        {
            public: 
                class iterator 
                {

                }; 
        }; 
    }; 
}; 

// Client 

void test(void)
{
    cpa::dsa::vector<int> v; 
    cpa::dsa::vector<int>::iterator iter = v.begin(); 
}

HEADER cpa_thread_pool 

namespace cpa 
{
    namespace sys 
    {
        namespace ps
        {
            class thread_pool
            {

            }; 
        }
    }
}

void test(void)
{
    cpa::sys::ps::thread_pool myThreadPool(15); 
}

#include <cpa> 
#include <list> 
#include <text_file> 

int main(void)
{
    cpa::application app; 

    cpa::dsa::list<int> myList; 
    cpa::sys::file::text_file myFile; 


    return app.exec(); 
}