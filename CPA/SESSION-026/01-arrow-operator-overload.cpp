#include <iostream> 

class Date 
{
    private: 
        int day, month, year; 
    public: 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year) 
        {
        }

        int getDay() const 
        {
            return day; 
        }

        void setDay(int newDay)
        {
            this->day = newDay; 
        }
}; 

class DatePtr 
{
    private: 
        Date* pDate; 
    public: 
        DatePtr(Date* _pDate) : pDate(_pDate) 
        {
            std::cout << "In CTOR: Address being put in pDate:" << _pDate << std::endl; 
        } 

        Date* operator->() 
        {
            std::cout << "In operator->:returning addr:" << pDate << std::endl; 
            return pDate; 
        }

        ~DatePtr()
        {
            std::cout << "In DTOR:Invoking delete on addr:" << pDate << std::endl; 
            delete this->pDate; 
            pDate = 0; 
        }
}; 

void test(void); 

int main(void)
{
    test(); 
    return (0); 
}

void test(void)
{
    DatePtr obj(new Date(20, 12, 2025)); 
    
    /*
    Date myDate(20, 12, 2025); 
    DatePtr obj(&myDate);   // Segfault in dtor
    */
   
    int day = obj->getDay(); 
    std::cout << "obj->getDay():" << day << std::endl; 
    obj->setDay(28); 
    day = obj->getDay(); 
    std::cout << "obj->getDay():" << day << std::endl; 
}

/* 
Internals of DatePtr obj(new Date(20, 12, 2025));  

STEP 1: 
    Internals of new Date(20, 12, 2025); 
    a) Date* tmp1 = (Date*)malloc(sizeof(Date));
    b) Date::Date(tmp1, 20, 12, 2025); 

STEP 2: 
    DatePtr obj(tmp1); 

    a)  Allocate memory on Stack frame of test() function 
        for obj 
    b)  DatePtr::DatePtr(&obj, tmp1); 
*/


