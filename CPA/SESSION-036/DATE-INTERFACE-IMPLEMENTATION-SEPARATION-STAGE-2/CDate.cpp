#include "CDate.hpp"
#include <iostream> 

CDate::CDate(int init_day, int init_month, int init_year) : day(init_day), 
                                                            month(init_month), 
                                                            year(init_year) 
{
    puts("CDate::CDate()"); 
}

int CDate::getDay()
{
    puts("CDate::getDay()"); 
    return day; 
}

int CDate::getMonth()
{
    puts("CDate::getMonth()"); 
    return month; 
}

int CDate::getYear()
{
    puts("CDate::getYear()"); 
    return year; 
}

void CDate::setDay(int newDay)
{
    puts("CDate::setDay()"); 
    day = newDay; 
}

void CDate::setMonth(int newMonth)
{
    puts("CDate::setMonth()"); 
    month = newMonth; 
}

void CDate::setYear(int newYear)
{
    puts("CDate::setYear()"); 
    year = newYear; 
}

void CDate::show()
{
    puts("CDate::show()"); 
    std::cout << day << "/" << month << "/" << year << std::endl; 
}

IDate* IDate::getDateInstance(int init_day, int init_month, int init_year)
{
    puts("IDate::getDateInstance()"); 
    return new CDate(init_day, init_month, init_year); 
}