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
        CDate(int init_day, int init_month, int init_year);
        int getDay(); 
        int getMonth(); 
        int getYear(); 
        void setDay(int newDay); 
        void setMonth(int newMonth); 
        void setYear(int newYear); 
        void show();
}; 

#endif 