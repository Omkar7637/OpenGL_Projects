#include <iostream> 
#include <cstdlib> 
#include <cstring> 

class Date 
{
    private: 
        int day, month, year; 
    public: 
        Date(int _day, int _month, int _year) : day(_day), month(_month), year(_year)
        {

        }

        int get_month() const 
        {
            return month; 
        }

        int get_year() const 
        {
            return year; 
        }
}; 

class DebitCard
{
    private: 
        char* db_name; 
        unsigned long long db_number; 
        Date* p_issue_date; 
        Date* p_valid_thru_date; 
        unsigned short cvv; 

    public: 
        DebitCard(const char* p_name, unsigned long long card_number, 
            int issue_month, int issue_year, int valid_thru_month, int valid_thru_year, unsigned short cvv)
        {
            size_t name_len = strlen(p_name); 
            this->db_name = new char[name_len + 1]; 
            strncpy((char*)db_name, p_name, name_len); 
            this->db_name[name_len] = '\0'; 
            
            this->db_number = card_number; 

            this->p_issue_date = new Date(-1, issue_month, issue_year); 
            this->p_valid_thru_date = new Date(-1, valid_thru_month, valid_thru_year); 

            this->cvv = cvv;         
        }

        ~DebitCard()
        {
            delete[] this->db_name; 
            delete this->p_issue_date; 
            delete this->p_valid_thru_date;
        }
       
        friend std::ostream& operator<<(std::ostream& os, const DebitCard& db_card); 
}; 

std::ostream& operator<<(std::ostream& os, const DebitCard& db_card)
{
    os << "Card Holder Name:" << db_card.db_name << std::endl; 
    os << "Card Number:" << db_card.db_number << std::endl; 
    os << "Issue Month/Issue Year:" << db_card.p_issue_date->get_month() << "/"
        << db_card.p_issue_date->get_year() << std::endl; 
    os << "Valid thru Month / Valid thru year:" << db_card.p_valid_thru_date->get_month() << "/"
            << db_card.p_valid_thru_date->get_year() << std::endl; 
    os << "CVV:" << db_card.cvv << std::endl; 
    return os; 
}  

void test_debit_card(void); 

int main(void)
{
    test_debit_card(); 
    return EXIT_SUCCESS; 
}

void test_debit_card(void)
{
    DebitCard* my_debit_card = new DebitCard("Yogeshwar Shukla", 1111222233334444, 12, 2020, 
        12, 2025, 111); 

    std::cout << *my_debit_card; 

    delete my_debit_card;  
    my_debit_card = 0; 
}

//  new operator = malloc() + automated call to constructor 
//  delete operator = automated call to destructor + free()