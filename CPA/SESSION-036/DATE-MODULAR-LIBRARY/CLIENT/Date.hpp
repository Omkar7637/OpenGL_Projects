#ifndef _DATE_HPP
#define _DATE_HPP 

//----------------Header files----------------
#include <iostream> 
#include <cstring> 

//----------------Definition of class Date----------------
class Date 
{
    private: 
        // ----------------typedefs----------------
        typedef int day_t; 
        typedef int month_t; 
        typedef int year_t; 

        //----------------non-static private members----------------
        day_t day; 
        month_t month; 
        year_t year; 

        //----------------private static consants----------------
        static const day_t VALID_START_DAY; 
        static const day_t VALID_END_DAY_FOR_LEAP_FEBRUARY; 
        static const day_t VALID_END_DAY_FOR_NONLEAP_FEBRUARY; 
        static const day_t VALID_END_DAY_FOR_THIRTY_DAY_MONTH; 
        static const day_t VALID_END_DAY_FOR_THIRTY_ONE_DAY_MONTH; 
        static const int FOUR; 
        static const int HUNDRED; 
        static const int FOUR_HUNDRED; 
        static const int ZERO; 
        static const int ONE; 
        static const year_t NINTEEN_SEVENTY; 

        //----------------enums----------------
        enum MONTH{
            JANUARY = 1, 
            FEBRUARY, 
            MARCH, 
            APRIL, 
            MAY, 
            JUNE, 
            JULY, 
            AUGUST, 
            SEPTEMBER, 
            OCTOBER, 
            NOVEMBER, 
            DECEMBER
        }; 
        
        //----------------private-static member functions----------------
        static bool is_year_leap(year_t year); 
        static bool is_date_valid(day_t day, month_t month, year_t year); 
    
    public: 
        //  ----------------Constructors----------------
        // Default constructor 
        Date(); 
        // Parameterized constructor 
        Date(day_t _day, month_t _month, year_t _year); 
        // ----------------getter functions----------------
        day_t get_day() const; 
        month_t get_month() const; 
        year_t get_year() const; 
        //----------------setter functions----------------
        void set_day(day_t new_day);
        void set_month(month_t new_month);
        void set_year(year_t new_year);   
        //----------------Miscallaneous functions----------------
        void show() const; 
};  

#endif // _DATE_HPP 