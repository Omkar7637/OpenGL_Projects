#include <iostream> 

class Base 
{
    private: 
        int private_num; 
    protected: 
        int protected_num; 
    public: 
        int public_num; 

        void b_member_function()
        {
            this->public_num = 1; 
            this->protected_num = 2; 
            this->private_num = 3; 

            Base myObjBase; 
            myObjBase.public_num = -1; 
            myObjBase.protected_num = -2; 
            myObjBase.private_num = -3; 
        }
}; 

class Derived : public Base 
{
    public: 
        void d_member_function()
        {
            Base myObjBase; 
            //  Two objects of class Base are available to d_member_function() 
            //  1:  this pointer of d_member_function() points to object of type Derived 
            //  which has a Base object embedded within it. 
            //  2:  d_member_function() has a local variable myObjBase which is an object 
            //      of class Base 
            //  From here, we can access public as well as protected attributes of Base object 
            //  embedded within derived object (which is pointed by this pointer)
            //  From here we can access only public members of myObjBase 
            myObjBase.public_num = 1000; 
            //  myObjBase.protected_num = 2000;     // CTE: protected access is granted only for those base objects 
                                                    //  which are embedded within derived object
            this->public_num = -1000; 
            this->protected_num = -2000; 

            Derived D; 
            D.protected_num = -1000; 
        }
}; 

void test(); 

int main(void)
{
    test(); 
    return 0; 
}

void test() 
{
    Base objBase; 

    objBase.public_num = 100;       //  test() is an external function to class 
                                    //  therefore only public members are accessible 
    // objBase.protected_num = 200;    //  CTE 
    // objBase.private_num = 300;      //  CTE 
}

//  External function with respect to class Base  -> global C like function which is not a friend of class Base 
//  Any member of function of any class which (a) does not belong to inheritance hierarchy rooted at class Base 
//  (b) is not a friend class of class Base -> ONLY PUBLIC ATTRIBUTES VISIBLE 