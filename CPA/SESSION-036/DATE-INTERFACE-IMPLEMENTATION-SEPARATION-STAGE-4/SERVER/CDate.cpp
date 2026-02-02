#include "CDate.hpp"
#include <iostream> 

CDate::CDate(int init_day, int init_month, int init_year) : day(init_day), 
                                                            month(init_month), 
                                                            year(init_year) 
{
  
}

int CDate::getDay()
{
  
    return day; 
}

int CDate::getMonth()
{
 
    return month; 
}

int CDate::getYear()
{
 
    return year; 
}

void CDate::setDay(int newDay)
{
  
    day = newDay; 
}

void CDate::setMonth(int newMonth)
{
  
    month = newMonth; 
}

void CDate::setYear(int newYear)
{
   
    year = newYear; 
}

void CDate::show()
{
   
    std::cout << day << "/" << month << "/" << year << std::endl; 
}

IDate* IDate::getDateInstance(int init_day, int init_month, int init_year)
{
    
    return new CDate(init_day, init_month, init_year); 
}