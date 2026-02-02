#include <iostream> 

class Base 
{
    public: 
        void f()
        {
            std::cout << "Base::f()" << std::endl; 
        }

        void g()
        {
            std::cout << "Base::g()" << std::endl; 
        }

        virtual void h() 
        {
            std::cout << "Base::h()" << std::endl; 
        }

        virtual void h(int num)
        {
            std::cout << "Base::h()" << std::endl;    
        }
}; 

class Derived : public Base 
{
    public: 
        void f() 
        {
            std::cout << "Derived::f()" << std::endl; 
        }

        void g()
        {
            std::cout << "Derived::g()" << std::endl; 
        }

        void h(int num)
        {
            std::cout << "Derived::h()" << std::endl; 
        }
}; 

void test_other_combinations(void); 
void test_virtual_combination(void); 

int main(void)
{
    test_other_combinations(); 
    test_virtual_combination(); 
    return (0); 
}

void test_other_combinations(void)
{
    std::cout << "----test_other_combinations()----" << std::endl; 
    Base B; 
    Derived D; 

    Base* pB = new Base; 
    Derived* pD = new Derived; 

    B.f();      // B::f() 
    B.g();      //  B::g() 

    pB->f();    // B::f() 
    pB->g();    //  B::g() 

    D.f();      //  D::f() 
    D.g();      //  D::g() 

    pD->f();    // D::f() 
    pD->g();    //  D::g() 

    delete pB; 
    pB = 0; 

    delete pD; 
    pD = 0; 
}

void test_virtual_combination(void)
{
    std::cout << "----test_virtual_combination()----" << std::endl; 
    Base* pB = new Derived; 

    pB->f();    //  B::f() 
    pB->g();    //  D::g()

    pB->h(); 
    pB->h(100);
    delete pB; 
    pB = 0; 
}

//  B* pB = new D; 
//  pB->f();        //  f() is present in both B and D and its is virtual 
//  pB->f() will be resolved to D::f() 

//  Q: Can we apply B::f() in this scenario? 
//  A: Yes, pB->B::f(); 