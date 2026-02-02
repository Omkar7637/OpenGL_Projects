#include "insertion_sort.hpp"

//  --------------------------------DATE CLASS START--------------------------------
//  Defining class Date for testing insertion_sort() template for 
//  user defined data type. This code explores the relationship 
//  between operator overloading and templates 

class Date 
{
    private:    
        int day, month, year; 
    public: 
        //  Parameterized constructor 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {
        }

        //  Default constructor 
        Date() 
        {

        }

        bool operator>(const Date& other) const 
        {
            if(this->year > other.year)
                return true; 
            else if(this->year < other.year)
                return false; 
            
            if(this->month > other.month)
                return true; 
            else if(this->month < other.month)
                return false; 

            if(this->day > other.day)
                return true; 
            else 
                return false; 
        }

        friend std::ostream& operator<<(std::ostream& os, const Date& dateObject); 
}; 

std::ostream& operator<<(std::ostream& os, const Date& dateObject)
{
    os << dateObject.day << "/" << dateObject.month << "/" << dateObject.year << std::endl; 
    return os; 
}
//  --------------------------------DATE CLASS END--------------------------------
void test_for_built_in_types(void); 
void test_for_user_defined_types(void); 

int main(void)
{
    test_for_built_in_types(); 
    test_for_user_defined_types(); 
    return (0); 
}

void test_for_built_in_types(void)
{
    std::cout << "----Entered test_for_built_in_types()----" << std::endl; 
    std::cout << "Array of Integers:" << std::endl; 
    int iArr[8] = {40, 25, 10, 24, 78, 90, 100, 200}; 
    show_array<int>(iArr, 8, "iArr:Before Sort:"); 
    insertion_sort<int>(iArr, 8); 
    show_array<int>(iArr, 8, "iArr:After Sort:"); 
    
    std::cout << "Array of doubles:" << std::endl; 
    double dArr[5] = {5.5, 4.4, 3.3, 2.2, 1.1}; 
    show_array(dArr, 5, "dArr:Before Sort:");
    insertion_sort(dArr, 5); 
    show_array(dArr, 5, "dArr:After Sort:");  

    std::cout << "----Leaving test_for_built_in_types()----" << std::endl;
}

void test_for_user_defined_types(void)
{
    std::cout << "----Entered test_for_user_defined_types()----" << std::endl;
    std::cout << "Array of Dates:" << std::endl; 
    Date dateArray[8] = {
        Date(25, 12, 2025), 
        Date(22, 4, 2021), 
        Date(23, 5, 2021), 
        Date(10, 5, 2021), 
        Date(24, 12, 2025), 
        Date(25, 12, 2025), 
        Date(4, 7, 2024), 
        Date(1, 1, 1970)
    }; 
    show_array<Date>(dateArray, 8, "dateArr:Before Sort:"); 
    insertion_sort<Date>(dateArray, 8); 
    show_array<Date>(dateArray, 8, "dateArr:After sort:"); 
    std::cout << "----Leaving test_for_user_defined_types()----" << std::endl;
}
