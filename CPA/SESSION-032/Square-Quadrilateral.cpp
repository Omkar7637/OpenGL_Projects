#include <iostream> 
#include <stdexcept> 

class Quadrilateral 
{
    private: 
        double s1, s2, s3, s4; 

    public: 
        Quadrilateral(double _s1, double _s2, double _s3, double _s4)
        {
            if(
                _s1 <= 0.0 || 
                _s2 <= 0.0 || 
                _s3 <= 0.0 || 
                _s4 <= 0.0 || 
                (_s1 + _s2 + _s3) <= _s4 || 
                (_s2 + _s3 + _s4) <= _s1 || 
                (_s3 + _s4 + _s1) <= _s2 || 
                (_s4 + _s1 + _s2) <= _s3 
            )
                throw std::domain_error("invalid values for sides of Quad"); 
            
            s1 = _s1; 
            s2 = _s2; 
            s3 = _s3; 
            s4 = _s4;  
        }

        double perimeter() const 
        {
            return s1 + s2 + s3 + s4; 
        }

        double area() const 
        {
            double s = this->perimeter() / 2; 
            return sqrt((s - s1) * (s - s2) * (s - s3) * (s - s4)); 
        } 

        void show () const 
        {
            std::cout << "s1:" << s1 << ",s2:" << s2 << ",s3:" << s3 << ",s4:" << s4 << std::endl;
        }
};



//  class Square : public Quadrilateral 
//  Square IS-A Quadrilateral 
class Square : public Quadrilateral 
{
    private: 
        double s; 
    public: 
        Square(double _s) : Quadrilateral(_s, _s, _s, _s)
        {

        }
}; 

void test_quadrilateral(); 

int main(void)
{
    test_quadrilateral(); 
    return EXIT_SUCCESS; 
}

void test_quadrilateral()
{
    Quadrilateral Q(2.1, 3.2, 4.5, 6.7); 

    double P = Q.perimeter(); 
    double A = Q.area(); 

    std::cout << "Perimeter:" << P << ", Area:" << A << std::endl;
}