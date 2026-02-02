#include <iostream> 
#include <cstdlib> 

class Vector3D
{
    private: 
        double x, y, z; 

    public: 
        Vector3D() : x(0.0), y(0.0), z(0.0)
        {
        }

        Vector3D(double _x, double _y, double _z) : x(_x), y(_y), z(_z)
        {
        }

        Vector3D operator+(const Vector3D& other) const 
        {
            return Vector3D(this->x + other.x, this->y + other.y, this->z + other.z); 
        }

        Vector3D operator-(const Vector3D& other) const 
        {
            return Vector3D(this->x - other.x, this->y - other.y, this->z - other.z); 
        }

        double dot(const Vector3D& other) const 
        {
            return (this->x * other.x + this->y * other.y + this->z * other.z); 
        }

        double mod() const 
        {
            return sqrt(x*x + y*y + z*z); 
        }

        Vector3D normalize() const 
        {
            double mag = mod(); 
            return Vector3D(x/mag, y/mag, z/mag); 
        }

        friend std::ostream& operator<<(std::ostream& os, const Vector3D& vecObject); 
        friend std::istream& operator>>(std::istream& is, Vector3D& vecObject); 
}; 

std::ostream& operator<<(std::ostream& os, const Vector3D& vecObject)
{
    os << "(" << vecObject.x << ")i+(" << vecObject.y << ")j+(" << vecObject.z << ")k" << std::endl; 
    return os;  
}

std::istream& operator>>(std::istream& is, Vector3D& vecObject)
{
    std::cout << "Enter value for x component of a 3D vector:"; 
    is >> vecObject.x; 
    std::cout << "Enter value for y component of a 3D vector:"; 
    is >> vecObject.y; 
    std::cout << "Enter value for z component of a 3D vector:"; 
    is >> vecObject.z;
    return is;  
}

//  CLASS MATERIAL + ALL EASY EXERCISES -> MORE THAN ENOUGH FOR INDIAN IT INDUSTRY (BARE MINIMUM GUY)

//  SELF PROBLEM SOLVERS : CLASS MATERIAL + ALL INTERMEDIATE EXERCISES (PROBLEM SOLVERS WITH FUNDAMENTAL UNDERSTANDING)

//  ZEN LEVEL : CLASS MATERIAL + ALL EXERCISES 