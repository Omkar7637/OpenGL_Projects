#include <stdio.h> 
#include <stdlib.h> 
#include <string.h> 

struct Date 
{
    int day; 
    int month; 
    int year; 
}; 

struct DebitCard
{
    char* db_name; 
    unsigned long long db_number;
    struct Date* p_issue_date; 
    struct Date* p_valid_thru_date; 
    unsigned short cvv; 
}; 

struct DebitCard* allocate_debit_card(
        const char* p_name, unsigned long long card_number, 
        int issue_month, int issue_year, int valid_thru_month, int valid_thru_year, 
        unsigned short cvv
    ); 

void show(struct DebitCard* p_debit_card); 


void test_debit_card(void); 

int main(void)
{
    test_debit_card(); 
    return (0); 
}

void test_debit_card(void)
{
    struct DebitCard* my_debit_card = NULL; 

    my_debit_card = allocate_debit_card("Yogeshwar Shukla", 1111222233334444, 12, 20, 12, 25, 111); 
    show(my_debit_card); 
    //  Directly writing following two lines will lead to memory leak 
    //  as explained in the class 
    //  free(my_debit_card); 
    //  my_debit_card = NULL; 

    //  Correct sequence for release 
    free(my_debit_card->db_name); 
    free(my_debit_card->p_issue_date); 
    free(my_debit_card->p_valid_thru_date); 
    free(my_debit_card); 
    my_debit_card = NULL; 
}

struct DebitCard* allocate_debit_card(
        const char* p_name, unsigned long long card_number, 
        int issue_month, int issue_year, int valid_thru_month, int valid_thru_year, 
        unsigned short cvv
    )
{
    struct DebitCard* p_new_debit_card = NULL; 

    p_new_debit_card = (struct DebitCard*)malloc(sizeof(struct DebitCard)); 
    if(p_new_debit_card == NULL)
    {
        fprintf(stderr, "malloc():fatal:memory allocation failed\n"); 
        exit(EXIT_FAILURE); 
    }

    //  Card holder name 
    size_t name_len = strlen(p_name); 
    p_new_debit_card->db_name = (char*)malloc(name_len + 1); 
    if(p_new_debit_card->db_name == NULL)
    {
        fprintf(stderr, "malloc():fatal:out of memory\n"); 
        exit(EXIT_FAILURE); 
    }
    strncpy(p_new_debit_card->db_name, p_name, name_len); 
    p_new_debit_card->db_name[name_len] = '\0'; 

    //  Card number 
    p_new_debit_card->db_number = card_number; 

    //  Issue date 
    p_new_debit_card->p_issue_date = (struct Date*)malloc(sizeof(struct Date)); 
    if(p_new_debit_card->p_issue_date == NULL)
    {
        fprintf(stderr, "malloc():fatal:out of memory\n"); 
        exit(EXIT_FAILURE); 
    }
    p_new_debit_card->p_issue_date->day = -1; 
    p_new_debit_card->p_issue_date->month = issue_month; 
    p_new_debit_card->p_issue_date->year = issue_year; 

    //  Valid thru date 
    p_new_debit_card->p_valid_thru_date = (struct Date*)malloc(sizeof(struct Date)); 
    if(p_new_debit_card->p_valid_thru_date == NULL)
    {
        fprintf(stderr, "malloc():fatal:out of memory\n"); 
        exit(EXIT_FAILURE); 
    }
    p_new_debit_card->p_valid_thru_date->day = -1; 
    p_new_debit_card->p_valid_thru_date->month = valid_thru_month; 
    p_new_debit_card->p_valid_thru_date->year = valid_thru_year; 

    //  CVV 
    p_new_debit_card->cvv = cvv; 

    return (p_new_debit_card); 
}

void show(struct DebitCard* p_debit_card)
{
    printf("Card Holder Name:%s\n", p_debit_card->db_name); 
    printf("Card Number:%llu\n", p_debit_card->db_number); 
    printf("Issue Month/Issue Year:%d/%d\n", p_debit_card->p_issue_date->month, 
        p_debit_card->p_issue_date->year); 
    printf("Valid Thru Month/Valid Thru Year:%d/%d\n", p_debit_card->p_valid_thru_date->month, 
        p_debit_card->p_valid_thru_date->year); 
    printf("CVV:%hu\n", p_debit_card->cvv); 
}