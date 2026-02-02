// Header file inclusion
#include <stdio.h>
#include <stdlib.h>

// Type declarations
struct Date
{
    int day;
    int month;
    int year;
};

// Functions declarations
struct Date* getDateInstance(int _day, int _month, int _year);
int getDay(struct Date* pDate);
int getMonth(struct Date* pDate);
int getYear(struct Date* pDate);
void setDay(struct Date* pDate, int newDay);
void setMonth(struct Date* pDate, int newMonth);
void setYear(struct Date* pDate, int newYear);
void showDate(struct Date* pDate);
void releaseDate(struct Date* pDate);


// Entry point function
int main(void)
{
    struct Date* examDate = NULL;

    examDate = getDateInstance(30, 9, 2025);

    int examDay = getDay(examDate);
    int examMonth = getMonth(examDate);
    int examYear = getYear(examDate);

    printf("Testing getters:exam date:%d/%d/%d\n", examDay, examMonth, examYear);
    puts("Testing showDate():");
    showDate(examDate);

    setDay(examDate, 31);
    setMonth(examDate, 10);
    setYear(examDate, 2026);

    puts("Testing setters:");
    showDate(examDate);

    releaseDate(examDate);
    examDate = NULL;

    return (0);
}

// Implementation of functions
struct Date* getDateInstance(int _day, int _month, int _year)
{
    struct Date* newDate = NULL;

    newDate = (struct Date*)malloc(sizeof(struct Date));
    if(newDate == NULL)
    {
        puts("Out of memory");
        exit(EXIT_FAILURE);
    }

    newDate->day = _day;
    newDate->month = _month;
    newDate->year = _year;

    return (newDate);
}

int getDay(struct Date* pDate)
{
    return (pDate->day);
}

int getMonth(struct Date* pDate)
{
    return (pDate->month);
}

int getYear(struct Date* pDate)
{
    return (pDate->year);
}

void setDay(struct Date* pDate, int newDay)
{
    pDate->day = newDay;
}

void setMonth(struct Date* pDate, int newMonth)
{
    pDate->month = newMonth;
}

void setYear(struct Date* pDate, int newYear)
{
    pDate->year = newYear;
}

void showDate(struct Date* pDate)
{
    printf("%d/%d/%d\n", pDate->day, pDate->month, pDate->year);
}

void releaseDate(struct Date* pDate)
{
    free(pDate);
    pDate = NULL;
}
