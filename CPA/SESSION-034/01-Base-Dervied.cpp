#include <iostream> 

class B1
{
    public: 
        void f1() 
        {
            std::cout << "B1::f1()" << std::endl; 
        }

        virtual void f2() 
        {
            std::cout << "B1::f2()" << std::endl; 
        }

        void f3() 
        {
            std::cout << "B1::f3()" << std::endl; 
        }
}; 

class D1 : public B1 
{
    public:
        //  Overriding non-virtual member function f1() from base class B1  
        void f1() 
        {
            std::cout << "D1::f1()" << std::endl; 
        }

        //  Overriding virtual member function f2() from base class B1 
        void f2() 
        {
            std::cout << "D1::f2()" << std::endl; 
        }

        //  Derived specific function 
        void g() 
        {
            std::cout << "D1::g()" << std::endl; 
        }
}; 

void object_of_D1_in_D1_pointer(); 
void object_of_D1_in_B1_pointer(); 

int main(void)
{
    object_of_D1_in_D1_pointer(); 
    object_of_D1_in_B1_pointer(); 
    return (0);
}

void object_of_D1_in_D1_pointer()
{
    D1* pD1 = new D1; 

    pD1->f1();  //  D1::f1(),   overridden version from D1, f1() is not virtual in B1
    pD1->f2();  //  D1::f2(),   overridden version from D1, f2() is virtual in B1 
    pD1->g();   //  D1::g(),    Derived specific member function of g() 
    pD1->f3();  //  B1::f3(),   inheritor from B1 

    pD1->B1::f1();  //  B1::f1(), explicitly invoking base class' version of f1() 
                    //  on base class object embedded in derived class object 
    pD1->B1::f2();  //  B1::f2(), explicitly invoking base class' version of f2() 
                    //  on base class object embedded in derived class' object
    delete pD1; 
}

void object_of_D1_in_B1_pointer()
{
    B1* pB1 = new D1; 

    pB1->f3();  //  B1::f3() will be called, there is no other version of f3()
    pB1->f1();  //  B1::f1() will be called, even though f1() is overridden in D1 
                //  though object is of type D1, compiler by default considers 
                //  type of pointer to resolve the call 
    pB1->f2();  //  D1::f2() will be called, f2() is overrideen in Derived class, 
                //  and it is marked as virtual in Base class, therefore, C++ compiler 
                //  rules in favour of object type and type(object) == D1, hence D1::f2() 

    //  Even though f2() is made virtual, what if we want to invoke base class' version 
    //  of f2(), despite object is of derived type 
    //  In this case we have to explicitly resolve the scope of f2() so that compiler does not 
    //  have to resolve it. (Because if you ask compiler to resolve the scope of f2() then by its 
    //  rule it will go to derived class' version of f2() -> which we want to avoid in this case)
    pB1->B1::f2(); 
    
    //  @goal: type(pointer) == Base, type(object) == Derived
    //  member function -> non virtual 
    //  Yet we want to invoke derived class' version of member function 
    //  The following syntax will not work because of scope of Derived 
    //  class is not embedded within base class, it is other way round 
    //  pB1->D1::f1();  //  Compile time error

    ((D1*)pB1)->f1();               //  C-style type casting syntax 
    dynamic_cast<D1*>(pB1)->f1();   //  C++ style type casting syntax 
    dynamic_cast<D1*>(pB1)->g();    //  D1::g() 

    delete pB1;
}

// Expression : 
//  Valid combination of operators and operands 
//  Every variable has a declared type 
//  Considering declared types of all involved variables 
//  and used operators : compiler derives the type of 
//  evlauation of expression 
//  INFERRED TYPE OF EXPRESSION : Ti 
//  int a, b; 
//  type(a) == int      .... declared 
//  type(b) == int      .... declared 
//  type(a+b) == int    .... inferred (compiler has a type inference algortihm)
//  c = a + b; 

//  (float)(a + b)

//  Let expr be an expression whose inferred type is Ti 
//  If we write Operation((Tc)expr)
//  Then the meaning operation will be decided as per Tc 
//  and will be applied to data value or data object of type Ti 
//  which is an evaluation of expr

//  ((float)a)/b

//  Let Ti be the type p
//  ((Tc)p)->f(); 

