#include "Date.hpp"

const Date::day_t Date::VALID_START_DAY                         = 1; 
const Date::day_t Date::VALID_END_DAY_FOR_LEAP_FEBRUARY         = 29; 
const Date::day_t Date::VALID_END_DAY_FOR_NONLEAP_FEBRUARY      = 28; 
const Date::day_t Date::VALID_END_DAY_FOR_THIRTY_DAY_MONTH      = 30; 
const Date::day_t Date::VALID_END_DAY_FOR_THIRTY_ONE_DAY_MONTH  = 31; 
const Date::year_t Date::NINTEEN_SEVENTY                        = 1970; 

const int Date::FOUR            = 4; 
const int Date::HUNDRED         = 100; 
const int Date::FOUR_HUNDRED    = 400; 
const int Date::ZERO            = 0; 
const int Date::ONE             = 1; 

  //----------------private-static member functions----------------
bool Date::is_year_leap(year_t year)
{
    return (
                (year % FOUR == ZERO && year % HUNDRED != ZERO) 
                || 
                (year % FOUR_HUNDRED == ZERO)
            ); 
}

bool Date::is_date_valid(day_t day, month_t month, year_t year)
{
    return  (
                (month == FEBRUARY && is_year_leap(year) && (day >= VALID_START_DAY && day <= VALID_END_DAY_FOR_LEAP_FEBRUARY)) 
                || 
                (month == FEBRUARY && !is_year_leap(year) && (day >= VALID_START_DAY && day <= VALID_END_DAY_FOR_NONLEAP_FEBRUARY)) 
                || 
                (
                    (month == JANUARY || month == MARCH || month == MAY || month == JULY 
                    || month == AUGUST || month == OCTOBER || month == DECEMBER) && 
                    (day >= VALID_START_DAY && day <= VALID_END_DAY_FOR_THIRTY_ONE_DAY_MONTH)
                ) 
                ||
                (
                    (month == APRIL || month == JUNE || month == SEPTEMBER || month == NOVEMBER) && 
                    (day >= VALID_START_DAY && day <= VALID_END_DAY_FOR_THIRTY_DAY_MONTH)
                )
            );
}

//  ----------------Constructors----------------
        // Default constructor 
Date::Date() : day(ONE), month(ONE), year(NINTEEN_SEVENTY)
{

}

// Parameterized constructor 
Date::Date(day_t _day, month_t _month, year_t _year) 
{   
    bool date_alidation_flag; 

    date_alidation_flag = is_date_valid(_day, _month, _year); 
    
    if(date_alidation_flag == false)
    {
        std::cerr << "Invalid Date Values, setting day, month, year to epoch date" << std::endl; 
    }

    this->day = date_alidation_flag != false ? _day : ONE; 
    this->month = date_alidation_flag != false ? _month : ONE; 
    this->year = date_alidation_flag != false ? _year : NINTEEN_SEVENTY; 
}

// ----------------getter functions----------------
Date::day_t Date::get_day() const 
{
    return this->day; 
}

Date::month_t Date::get_month() const 
{
    return this->month; 
}

Date::year_t Date::get_year() const 
{
    return this->year; 
}

//----------------setter functions----------------
void Date::set_day(day_t new_day)
{
    // validation check
    if(is_date_valid(new_day, this->month, this->year) == false)
    {
        std::cerr << "Invalid value for new_day, not changing anything" << std::endl; 
        return; 
    }

    this->day = new_day;
}

void Date::set_month(month_t new_month)
{
    if(is_date_valid(this->day, new_month, this->year) == false)
    {
        std::cerr << "Bad value for new month or existing day not compatible with new_month" << std::endl; 
        return; 
    }

    this->month = new_month; 
}

void Date::set_year(year_t new_year)
{
    this->year = new_year; 
}

//----------------Miscallaneous functions----------------
void Date::show() const 
{
    std::cout << this->day << "/" << this->month << "/" << this->year << std::endl; 
}