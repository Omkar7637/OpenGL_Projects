#include <iostream> 

class Date 
{
    private: 
        int day; 
        int month; 
        int year; 
    public: 
        Date() {} 

        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }
}; 

int main(void)
{
    Date myDate;    // Data definition statement 

    Date* pDate1 =  new Date;   //  Default CC
    //or    
    Date* pDate2 = new Date();  //  Default CC   

    Date* pDate3 = new Date(14, 12, 2025);  //  Parameterized CC 

    delete pDate1; 
    pDate1 = 0; 

    delete pDate2; 
    pDate2 = 0; 

    delete pDate3; 
    pDate3 = 0; 

    int* p_array = new int[5];
    
    std::cout << "Enter size of array:"; 
    size_t size; 
    std::cin >> size; 
    if(size)
    {
        int* p_array_2 = new int[size]; 

        delete[] p_array_2; 
        p_array_2 = 0;
    }

    delete[] p_array; 
    p_array = 0; 
}

//  new operator = malloc() + AUTOMATED CALL TO CONSTRUCTOR 
//  Date* pDate3 = new Date(14, 12, 2025); 

//  Date* tmp = (Date*)malloc(sizeof(Date));    //  Internal STEP 1 of new operator 
//  Date::Date(tmp, 14, 12, 2025);              //  Internal STEP 2 of new operator 

//  pDate3 = tmp; 

//  Date* pDate1 = new Date; 
//  Date* tmp = (Date*)malloc(sizeof(Date));    //  Internal STEP 1 of new operator  
//  Date::Date(tmp);                            //  Internal STEP 2 of new operator 