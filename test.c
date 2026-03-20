#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
//Complete the following function.


void calculate_the_maximum(int n, int k) {
  //Write your code here.
  int and_max = 0;
  int or_max = 0;
  int xor_max = 0;


    for(int a = 0; a < k; a++)
    {
        for (int b = a + 1; b < n; b++) 
        {
            int and_val = a & b;
            int or_val = a | b;
            int xor_val = a ^ b;

            if(and_val < k && and_val > and_max)
            {
                and_max = and_val;
            }
            if(or_val < k && or_val > or_max)
            {
                or_max = or_val;
            }
            if(xor_val < k && xor_val > xor_max)
            {
                xor_max = xor_val;
            }

        }
    }

    printf("and_max %d\n", and_max);
    printf("or_max %d\n", or_max);
    printf("xor_max %d\n", xor_max);
}

int main() {
    int n, k;
  
    scanf("%d %d", &n, &k);
    calculate_the_maximum(n, k);
 
    return 0;
}
