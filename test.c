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
            printf("%d & %d = %d\n", a, b, a & b);
            and_max = a & b;
        }

    }
  
}

int main() {
    int n, k;
  
    scanf("%d %d", &n, &k);
    calculate_the_maximum(n, k);
 
    return 0;
}
