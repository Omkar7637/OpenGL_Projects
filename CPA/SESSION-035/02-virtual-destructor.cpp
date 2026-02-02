#include <iostream> 

class Base 
{
    private: 
        int num; 
    public: 
        Base(int _num = 0) : num(_num) 
        {
        }

        virtual ~Base()
        {
            std::cout << "In ~Base()" << std::endl; 
            //  If base class has pointer variables pointing to dynamic blocks 
            //  and they must be freed before object de-allocation 
            //  to avoid memory - leak then 
            //  delete those pointers here 
            //  Call to Base::~Base() will be implicitly done by the compiler 
        }
}; 

class Derived : public Base 
{
    private: 
        int* pa; 
        float fnum; 
    public: 
        Derived(int k, float _fnum, int num_for_base = 0) : Base(num_for_base), pa(new int(k)), fnum(_fnum)
        {
        }

        ~Derived() 
        {
            
            std::cout << "In ~Derived()" << std::endl; 
            delete pa; 
            pa = 0; 
        }
}; 

void test(); 

int main() 
{
    test(); 
    return 0; 
}

void test() 
{
    Base* basePtr = new Derived(100, 1.1f); 

    delete basePtr;    
}

//  Without virtual destructor 
//  Case 1) Does base class have any other virtual function? 
//          if yes, 
//          delete dynamic_cast<Derived*>(basePtr);
//  Case 2) No, 
//          delete reinterpret_cast<Derived*>(basePtr); 

//  Enhannced Interpretation of virtual destructor 
//  You can make Base class destructor virtual to achieve same effect 
//  without such type-casting manoeuvring. 