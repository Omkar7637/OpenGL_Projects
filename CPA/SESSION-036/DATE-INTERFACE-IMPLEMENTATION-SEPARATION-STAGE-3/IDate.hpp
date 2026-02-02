#ifndef IDATE_HPP 
#define IDATE_HPP 

class IDate
{
    public: 
        virtual int getDay(); 
        virtual int getMonth(); 
        virtual int getYear(); 
        virtual void setDay(int newDay); 
        virtual void setMonth(int newMonth); 
        virtual void setYear(int newYear); 
        virtual void show();
        static IDate* getDateInstance(int initDay, int initMonth, int initYear); 
}; 


#endif // IDATE_HPP 