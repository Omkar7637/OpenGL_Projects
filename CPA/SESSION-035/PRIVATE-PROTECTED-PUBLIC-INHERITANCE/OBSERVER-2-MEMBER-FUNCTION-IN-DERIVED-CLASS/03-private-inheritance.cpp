#include <cstdio> 

class B11
{
    private: 
        int B11_private_num; 
    protected: 
        int B11_protected_num; 
    public: 
        int B11_public_num; 
}; 

class D11 : private B11 
{
    private: 
        int D11_private_num; 
    protected: 
        int D11_protected_num; 
    public: 
        int D11_public_num; 
}; 

class D12 : public D11 
{
    private: 
        int D12_private_num; 
    protected: 
        int D12_protected_num; 
    public: 
        int D12_public_num; 

        void d12_member_function()
        {
            //  Because D11 has privately inherited from B11, 
            //  public and protected members of B11 that were visible 
            //  here in the past (in case of protected and public inheritance)
            //  are no longer visible now ! 
            //  this->B11_protected_num = 100;      //  CTE 
            //  this->B11_public_num = 200;         //  CTE 
            
            this->D11_protected_num = 300;      //  ok 
            this->D11_public_num = 400;         //  ok 

            this->D12_private_num = 500;        //  ok 
            this->D12_protected_num = 600;      //  ok 
            this->D12_public_num = 700;         //  ok 

            //  Cannot access D11_private_num, B11_private_num 
        }
}; 

int main()
{
    return 0; 
}