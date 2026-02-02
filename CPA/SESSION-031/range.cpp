/* 
    How built in class range works in Python. 
    range(start_number, end_number)

    Object of class range contains numbers from 
    start_number to end_number-1 

    range(number)

    Object of range class contains numbers from 
    0 to number - 1. 

    (
        Point 1: In python, applying call operator () 
        after class name is enough to create an object 
        of class 

        so range() -> lets Python know that the programmer 
        wants to create an object of class range. 

        In between paranthesis, we give initialization data 
        that is passed to the constructor of the class 

        Point 2: The way iterator design pattern is supported 
        in Python, the range class does not 'actually' store
        the numbers from start_number to end_number - 1, 
        rather the next number is computed at run time at the 
        start of every iteration 

        refer range_demo.py file in the current directory 
    )
*/

#include <iostream> 

//-------------------RANGE-SERVER-SIDE-START
class range 
{
    private: 
        int start_num, end_num; 
    public: 
        range(int _start_num, int _end_num) : start_num(_start_num), end_num(_end_num)
        {
            //  TODO: assert: start_num < end_num else throw an exception 
        }

        range(int _end_num) : start_num(0), end_num(_end_num)
        {
            //  TODO: assert: start_num < end_num else throw an exception 
        }

        class iterator 
        {
            private: 
                int n; 
            public: 
                iterator(int _n = 0) : n(_n) 
                {

                }

                int operator*() const
                {
                    return n; 
                } 

                iterator& operator++()
                {
                    ++n; 
                    return *this; 
                }

                bool operator!=(const iterator& other) const 
                {
                    return n != other.n; 
                }
        }; 

        iterator begin() 
        {
            return iterator(start_num); 
        }

        iterator end() 
        {
            return iterator(end_num); 
        }
}; 


//-------------------RANGE-CLIENT-SIDE-START
int main(void)
{
    range R(10, 20); 

    for(
        range::iterator iter = R.begin(); 
        iter != R.end(); 
        ++iter 
    )
        std::cout << *iter << std::endl;    //  10 to 19 

    std::cout << "-----------------------------------" << std::endl; 

    range Q(8); 
    for(
        range::iterator iter = Q.begin(); 
        iter != Q.end(); 
        ++iter 
    )
        std::cout << *iter << std::endl;    //  0 to 7 

    return (0); 
}

//-------------------RANGE-CLIENT-SIDE-END