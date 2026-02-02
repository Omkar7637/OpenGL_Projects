#ifndef IDATE_HPP 
#define IDATE_HPP 

class IDate
{
    public: 
        virtual int getDay() = 0; 
        virtual int getMonth() = 0; 
        virtual int getYear() = 0; 
        virtual void setDay(int newDay) = 0; 
        virtual void setMonth(int newMonth) = 0; 
        virtual void setYear(int newYear) = 0; 
        virtual void show() = 0;
        static IDate* getDateInstance(int initDay, int initMonth, int initYear); 
}; 


#endif // IDATE_HPP 

