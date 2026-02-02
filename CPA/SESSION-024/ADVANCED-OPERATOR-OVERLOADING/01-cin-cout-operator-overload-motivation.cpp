#include <iostream> 

class Date 
{
    private: 
        int day, month, year; 
    public: 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }

        void show() const 
        {
            std::cout << day << "/" << month << "/" << year << std::endl; 
        }
}; 

int main(void)
{
    Date myDate(13, 12, 2025); 

    myDate.show(); 

    //  If we had cout operator overloaded
    //  both disadvantages of dedicated member function 
    //  such as show() would disappear 
    //  Disadvantage 1: Name such as show() will different for different class. 
    //  Disadvantage 2: Multiple objects cannot be defined on single 
    //  For every object to be displayed one call to a member function such as 
    //  show() must be made 

    //  The following code snippets illustrates how things would be different 
    //  if we have cout operator overloaded. 
    //std::cout << "Showing myDate:" << myDate << std::endl 
    //            << "Showing myDate2:" << myDate2 << std::endl; 

    return (0); 
}