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

  for (int i = n; i < k; i++)
  {
    for(int j = n+1; j < k; j++)
    {
        if((i & j) < k)
        {
            and_max = i & j;      
        }
    }
  }
  
  printf("%d\n", and_max);
  printf("%d\n", or_max);
  printf("%d\n", xor_max);
  
}

int main() {
    int n, k;
  
    scanf("%d %d", &n, &k);
    calculate_the_maximum(n, k);
 
    return 0;
}
