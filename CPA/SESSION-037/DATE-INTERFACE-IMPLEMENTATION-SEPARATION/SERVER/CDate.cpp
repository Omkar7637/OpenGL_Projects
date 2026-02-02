#include "CDate.hpp"
#include <iostream> 

CDate::CDate(int initDay, int initMonth, int initYear) :    day(initDay), 
                                                            month(initMonth), 
                                                            year(initYear)
{

}                                                        

int CDate::getDay() const
{
    return day; 
}

int CDate::getMonth() const
{
    return month; 
}

int CDate::getYear() const
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

void CDate::show(const char* msg) const
{
    if(msg)
        std::cout << msg << std::endl; 

    std::cout << day << "/" << month << "/" << year << std::endl; 
}

IDate* IDate::getInstance(int initDay, int initMonth, int initYear)
{
    return new CDate(initDay, initMonth, initYear); 
}

void IDate::releaseDate(IDate** ppIDate)
{
    IDate* pIDate = *ppIDate; 

    delete dynamic_cast<CDate*>(pIDate); 
}