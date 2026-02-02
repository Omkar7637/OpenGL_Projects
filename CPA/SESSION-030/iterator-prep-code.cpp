#include <iostream>

class array 
{
    private: 
        int* p; 
        int N; 
    public: 
        array(int _N) : N(_N), p(new int[_N])
        {

        }

        void show() 
        {
            for(int i = 0; i < N; ++i)
                std::cout << p[i] << std::endl; 
        }

        void add_by_5() 
        {
            for(int i = 0; i < N; ++i)
                p[i] += 5; 
        }
}; 
/////////////////////////////////////////////////////////////////////////////////////////
class node 
{
    friend class list; 
    private: 
        int data; 
        node* prev; 
        node* next; 
        node(int _data) : data(_data), prev(0), next(0)
        {

        }
};

class list 
{
    private: 
        node* head_node; 

    public: 
        void show() 
        {
            for(node* run = head_node->next; run != head_node; run = run->next)
                std::cout << run->data << std::endl; 
        }

        void add_by_5()
        {
            for(node* run = head_node->next; run != head_node; run = run->next)
                run->data += 5; 
        }
}; 
////////////////////////////////////////////////////////////////////////////////////////

//  CONTAINER TYPE 

void test(void)
{
    array A(10); 
    list L; 

    A.show(); 
    L.show(); 

    A.add_by_5(); 
    L.add_by_5(); 

    /* 
        Insetead of adding a member function per operation which requires 
        visiting every element in the array or the list 

        if we can create a loop at CLIENT SITE: something along the following line 

        for every element in A: 
            do something with element 

        for every element in L: 
            do something with element 
    */ 
}

