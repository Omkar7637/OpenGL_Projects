#ifndef IDATE_HPP 
#define IDATE_HPP 

class IDate
{
    public: 
        virtual int getDay() const = 0; 
        virtual int getMonth() const = 0; 
        virtual int getYear() const = 0; 
        virtual void setDay(int newday) = 0; 
        virtual void setMonth(int newMonth) = 0; 
        virtual void setYear(int newYear) = 0; 
        virtual void show(const char* msg = 0) const = 0; 
        static IDate* getInstance(int initDay, int initMonth, int initYear); 
        static void releaseDate(IDate** ppIDate); 
}; 

#endif  //  IDATE_HPP