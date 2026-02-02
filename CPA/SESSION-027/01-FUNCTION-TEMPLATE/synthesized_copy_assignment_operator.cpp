#include <iostream> 

class Date 
{
    private: 
        int day, month, year;

    public: 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }

        Date() : day(1), month(1), year(1970) 
        {

        }

        void show(const char* msg = 0) const 
        {
            if(msg)
                std::cout << msg << std::endl; 
            std::cout << day << "/" << month << "/" << year << std::endl; 
        } 
}; 

int main(void)
{
    Date D1(3, 1, 2026); 
    Date D2; 

    D1.show("D1:"); 
    D2.show("D2:"); 

    D2 = D1;    //  SYNTHESIZED COPY ASSIGNMENT OPERATOR 
    //  Date::operator=(&D2, D1)

    D1.show("D1:"); 
    D2.show("D2 after executing D2 = D1:");
    
    return 0; 
}

/*
class Date 
{
    //  Copy assignment operator
    Date& operator=(const Date& rhs) 
    {
        memcpy((void*)this, (void*)&rhs, sizeof(Date)); 
       
        return *this; 
    }
}; 

class T 
{
    public:
        T& operator=(const T& other)
        {
            memcpy((void*)this, (void*)&other, sizeof(T)); 
            return *this; 
        }
}; 
*/