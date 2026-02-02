#include "IDate.hpp"
#include <iostream> 

void testDate(); 

int main() 
{
    testDate(); 
    return (0); 
}

void testDate() 
{
    IDate* myDate = IDate::getDateInstance(31, 1, 2026); 

    myDate->show(); 
    myDate->setDay(4); 
    myDate->show(); 

    int month = myDate->getMonth(); 
    std::cout << "month:" << month << std::endl; 

    delete myDate; 
    myDate = 0; 
}

// # cl /EHsc /Fe:app.exe DateClient.cpp Date.lib
// # app.exe