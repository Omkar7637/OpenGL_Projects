#ifndef IDATE_HPP 
#define IDATE_HPP 

class IDate
{
    public: 
        int getDay(); 
        int getMonth(); 
        int getYear(); 
        void setDay(int newDay); 
        void setMonth(int newMonth); 
        void setYear(int newYear); 
        void show();
        static IDate* getDateInstance(int initDay, int initMonth, int initYear); 
}; 


#endif // IDATE_HPP 