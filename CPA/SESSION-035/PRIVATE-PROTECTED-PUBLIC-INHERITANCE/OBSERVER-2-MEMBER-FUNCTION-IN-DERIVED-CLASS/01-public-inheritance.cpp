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

class D11 : public B11 
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
            this->B11_protected_num = 100;      //  ok 
            this->B11_public_num = 200;         //  ok 
            
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
    return (0); 
}