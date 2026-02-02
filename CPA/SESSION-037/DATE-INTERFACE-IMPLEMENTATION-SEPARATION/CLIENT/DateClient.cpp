#include "IDate.hpp"
#include <iostream>
#include <cstdlib> 

// If you want you can link library using the following preprocessor directive 
// #pragma comment(lib, "Date.lib")

void testDate(); 

int main()
{
    testDate(); 
    return EXIT_SUCCESS; 
}

void testDate() 
{
    IDate* pIDate = IDate::getInstance(1, 2, 2026); 

    pIDate->show("Showing Date immediately after creation:"); 

    pIDate->setDay(5); 
    pIDate->setMonth(6); 
    pIDate->setYear(2028); 

    int day = pIDate->getDay(); 
    int month = pIDate->getMonth(); 
    int year = pIDate->getYear(); 

    std::cout << "Testing setters and getters:" << std::endl; 
    std::cout << day << "/" << month << "/" << year << std::endl; 

    pIDate->show("Showing after setters/getters"); 

    IDate::releaseDate(&pIDate); 
}