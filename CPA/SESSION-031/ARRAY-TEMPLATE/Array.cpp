#include "Array.hpp"

//============================CLASS DATE - START======================================
class Date 
{
    private: 
        int day, month, year; 
    public: 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }

        //  Default constructor is required for T key; in sort() function of Array template  
        Date() 
        {
        }

        //  > operator must be overloaded to support: p_array[i] > key in sort() of Array template 
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

        //  operator==() is required for p_array[i] == searchObject in find() function of Array template
        bool operator==(const Date& other)
        {
            return (this->day == other.day && this->month == other.month && this->year == other.year); 
        }

        friend std::ostream& operator<<(std::ostream& os, const Date& dateObject); 
}; 

std::ostream& operator<<(std::ostream& os, const Date& dateObject)
{
    os << dateObject.day << "/" << dateObject.month << "/" << dateObject.year << std::endl; 
    return os; 
} 
//============================CLASS DATE - END======================================  

void test_for_built_in_types(void); 
void test_for_user_defined_type(void);
void test_for_iterator(void); 

int main(void)
{
    test_for_built_in_types(); 
    test_for_user_defined_type(); 
    test_for_iterator(); 
    return (0); 
}

void test_for_built_in_types(void)
{
    //  Array of intgers 
    Array<int, 5> A_int; 
    A_int[0] = 30; 
    A_int[1] = 20; 
    A_int[2] = 15; 
    A_int[3] = 50; 
    A_int[4] = 5; 

    std::cout << "Before sort:" << std::endl; 
    for(std::size_t i = 0; i < A_int.size(); ++i)
        std::cout << "A_int[" << i << "]:" << A_int[i] << std::endl; 

    if(A_int.find(20) == true)
        std::cout << "20 is a part of array" << std::endl; 

    if(A_int.find(-30) == false) 
        std::cout << "-30 is not a part of array" << std::endl; 
        
    A_int.sort(); 

    std::cout << "After sort:" << std::endl; 
    for(std::size_t i = 0; i < A_int.size(); ++i)
        std::cout << "A_int[" << i << "]:" << A_int[i] << std::endl; 

    //  Test case for float 
    Array<float, 5> A_float; 
    A_float[0] = 5.5f; 
    A_float[1] = 3.2f; 
    A_float[2] = 1.1f; 
    A_float[3] = 7.6f; 
    A_float[4] = 0.5f; 

    std::cout << "Showing A_float before sort:" << std::endl; 
    for(ssize_t i = 0; i < A_float.size(); ++i)
        std::cout << "A_float[" << i << "]:" << A_float[i] << std::endl; 

    if(A_float.find(0.5f) == true)
        std::cout << "0.5f is a part of array" << std::endl; 

    if(A_float.find(45.4f) == false)
        std::cout << "45.4f is not a part of array" << std::endl; 

    A_float.sort(); 

    std::cout << "Showing A_float after sort:" << std::endl; 
    for(ssize_t i = 0; i < A_float.size(); ++i)
        std::cout << "A_float[" << i << "]:" << A_float[i] << std::endl; 
}

void test_for_user_defined_type(void)
{
    Array<Date, 5> dateArray; 

    dateArray[0] = Date(4, 1, 2025); 
    dateArray[1] = Date(2, 1, 2025); 
    dateArray[2] = Date(1, 1, 1970); 
    dateArray[3] = Date(2, 1, 1970); 
    dateArray[4] = Date(4, 5, 1999); 

    std::cout << "DateArray Before sort:" << std::endl; 
    for(ssize_t i = 0; i < dateArray.size(); ++i)
        std::cout << "dateArray[" << i << "]:" << dateArray[i]; 

    Date searchDateObject(2, 1, 1970); 

    // Date& searchObject = searchDateObject; // ok 
    //  Date & searchObject = Date(2, 1, 1970); 


    if(dateArray.find(Date(2, 1, 1970)) == true)
        std::cout << "2/1/1970 is a part of array" << std::endl; 

    if(dateArray.find(Date(2, 3, 1997)) == false)
        std::cout << "2/3/1997 is not a part of array" << std::endl; 

    dateArray.sort(); 

    std::cout << "DateArray After sort:" << std::endl; 
    for(ssize_t i = 0; i < dateArray.size(); ++i)
        std::cout << "dateArray[" << i << "]:" << dateArray[i]; 

    std::cout << "-------------------------------------------" << std::endl; 
    for(Array<Date, 5>::iterator iter = dateArray.begin(); iter != dateArray.end(); ++iter)
        std::cout << "*iter = " << *iter;
} 

void test_for_iterator(void)
{
    Array<int, 8> A; 

    std::cout << "----------test_for_iterator()-START--------------" << std::endl; 

    for(size_t index = 0; index < A.size(); ++index)
        A[index] = (index + 1) * 100; 

    for(Array<int,8>::iterator iter = A.begin(); iter != A.end(); ++iter)
        std::cout << "*iter=" << *iter << std::endl; 

    for(Array<int, 8>::iterator iter = A.begin(); iter != A.end(); ++iter)
        *iter = *iter + 5; 

    std::cout << "Showing Array A after increment all elements by 5" << std::endl; 
    for(Array<int,8>::iterator iter = A.begin(); iter != A.end(); ++iter)
        std::cout << "*iter=" << *iter << std::endl; 

    std::cout << "----------test_for_iterator()-END--------------" << std::endl; 
}