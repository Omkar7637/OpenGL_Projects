#include <iostream> 

class Date 
{
    friend std::ostream& operator<<(std::ostream& os, const Date& dateObject); 
    friend std::istream& operator>>(std::istream& is, Date& dateObject);
    private: 
        int day, month, year; 
    public: 
        Date() 
        {

        }

        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }

        void show() const 
        {
            std::cout << day << "/" << month << "/" << year << std::endl; 
        }
}; 

std::ostream& operator<<(std::ostream& os, const Date& dateObject)
{
    os << dateObject.day << "/" << dateObject.month << "/" << dateObject.year << std::endl;
    return os; 
}

std::istream& operator>>(std::istream& is, Date& dateObject)
{
    std::cout << "Enter valid value for day:"; 
    is >> dateObject.day; 
    std::cout << "Enter valid value for month:"; 
    is >> dateObject.month; 
    std::cout << "Enter valid value for year:"; 
    is >> dateObject.year; 

    return is; 
}


class Employee 
{

}; 

std::ostream& operator<<(std::ostream& os, const Employee& employeeObject)
{
    
    return os; 
}

void testOne(void); 
void testTwo(void); 

int main(void)
{
    testOne(); 
    testTwo(); 
    return EXIT_SUCCESS; 
}

void testOne(void)
{
    Date myDate1(13, 12, 2025); 
    Date myDate2(14, 12, 2025); 
    std::cout << "----Enetered testOne()-----" << std::endl; 
    std::cout << "myDate1:" << myDate1 << std::endl 
                << "myDate2:" << myDate2 << std::endl; 
    std::cout << "----Leaving testOne()-----" << std::endl; 
}

void testTwo(void)
{
    Date myDate; 
    Date myDate1, myDate2; 
    std::cout << "----Enetered testTwo()-----" << std::endl; 
    std::cin >> myDate;     // operator>>(std::cin, myDate)   

    std::cout << "----Testing chaining of cin operator----" << std::endl; 
    std::cin >> myDate1 >> myDate2;
    std::cout << "----Testing chaining of cin operator END----" << std::endl; 

    std::cout << "myDate:" << myDate << std::endl; 
    std::cout << "myDate1:" << myDate1 << std::endl;
    std::cout << "myDate2:" << myDate2 << std::endl;
    std::cout << "----Leaving testTwo()-----" << std::endl; 
}

/* 
    Function declaration: 

    class Complex {}; 
    
    void test() 
    {
        Complex c1(1.1, 2.2); 
        Compelx c2(3.3, 4.4); 

        Complex c3 = c1 + c2;   //  c3 = Complex::operator+(&c1, c2)

    }

    class Complex 
    {
        public: 
            Complex operator+(const complex &other) const
            {
                return Complex(this->re + other.re, this->im + other.im)
            }
    }

    //  Try to apply same approach for constructing a declaration for 
    std::cout << myDate; 

    //  First different: 
    For binary operator cout 
    LHS operand type != RHS operand type 

    Because << is a left associative operator 
    cout operator overload function must be defined in the 
    class of the LHS object. 

    ROADBLOCK: 
        type(std::cout)
        == 
        std::ostream (std namespace madhala ostream ha class)

    Definition of class Date is in your hand. 

    class Date 
    {
        public: 

            operator<<(const std::ostream& os)
            {
            
            }
    }; 

    You need to alter client side syntax for this 

    myDate << std::cout;    //  This is not good ! 
                            //  object chaining not possible 
                     
    MAIN ROADBLOCK: 
        std::cout << myDate;    //  Aai khayla det nahi 
        myDate << std::cout;    //  Baap bhik magun det nahi 

*/
 
/* 
    WAY OUT OF ROADBLOCK; 
    
    To support the following syntax
    
    std::cout << myDate; 

    C++ programming language asks programmer to write 
    cout operator overload function in a GLOBAL SCOPE 
    AND NOT AS A MEMBER OF SOME CLASS 

    We will define a global function named operator<< 

    What should be formal parameter list of such function? 
    The formal parameter list should be compatible with 
    types of two operands 

    First Operand: std::cout 
    Second Operand: myDate

    Why? 
    std::cout << myDate 
    will be converted into 
    operator<<(std::cout, myDate)

    First actual parameter: std::cout 
    First formal parameter: std::ostream&   (accept std::cout by reference 
                                            than by value)

    Second actual parameter: myDate 
    Second formal parameter: const Date&    (accept in reference to const)

    For object chaining return cout object (first actual parameter)
    by reference 

    std::cout << myDate1 << myDate2; 

    << is left associative: 

    std::cout << myDate1 
    == 
    operator<<(std::cout, myDate1)

    this call will return std::cout 

    Hence 

    (std::cout << myDate1)
    ==
    std::cout << myDate2 

    == 
    operator<<(std::cout, myDate2)

*/