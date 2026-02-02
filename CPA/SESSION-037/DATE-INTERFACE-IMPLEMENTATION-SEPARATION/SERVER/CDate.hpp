#ifndef CDATE_HPP
#define CDATE_HPP 

#include "IDate.hpp"

class CDate : public IDate 
{
    private: 
        int day; 
        int month; 
        int year; 
    public: 
        CDate(int initDay, int initMonth, int initYear); 
        int getDay() const; 
        int getMonth() const; 
        int getYear() const; 
        void setDay(int newday); 
        void setMonth(int newMonth) ;
        void setYear(int newYear); 
        void show(const char* msg = 0) const; 
}; 


#endif 