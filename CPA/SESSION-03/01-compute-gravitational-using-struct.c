//  Including standard input - output header
#include <stdio.h>


//  Defining a custom data type - ComputeGravitational
struct ComputeGravitational
{
    double m1;
    double m2;
    double r;
};


//  Function Declaration
double ComputeGravitationalForce(struct ComputeGravitational* pData);


//  Entry point function main()
int main(void)
{
    //  Variable declarations
    struct ComputeGravitational sunEarth;
    struct ComputeGravitational sunJupitor;

    double forceBetweenSunEarth;
    double forceBetweenSunJupitor;

    //  Code
    sunEarth.m1 = 1.9891e30;
    sunEarth.m2 = 5.9722e24;
    sunEarth.r = 149597871000;

    forceBetweenSunEarth = ComputeGravitationalForce(&sunEarth);
    printf("Gravitational Force Between the Sun and the Earth = (%lf) N\n", forceBetweenSunEarth);

    sunJupitor.m1 = 1.9891e30;
    sunJupitor.m2 = 1.89813e27;
    sunJupitor.r = 760070000000;

    forceBetweenSunJupitor = ComputeGravitationalForce(&sunJupitor);
    printf("Gravitational Force Between the sun and the Juiptor = (%lf) N\n", forceBetweenSunJupitor);

    return (0);
}


double ComputeGravitationalForce(struct ComputeGravitational* pData)
{
    double G = 6.67e-11;
    double F;

    F = (G * pData->m1 * pData->m2) / (pData->r * pData->r);

    return (F);
}
