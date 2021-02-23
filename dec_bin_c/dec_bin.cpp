#include <bits/stdc++.h>
using namespace std;

void dec_to_bin(unsigned int x, char *str)
{
    int len = 32, i = 0;
    while ( (x & (1 << (len - 1))) == 0 && len > 1) len--;
    str[len] = '\0';
    while (i < len && (str[i] = !!(x & (1 << (len - 1 - i++))) + '0') );
}


int dec_to_bin2(unsigned int x, char *str)
{
  unsigned int i; // ecx
  int result; // rax
  int j; // rdx
  int v3; // [rsp+10h] [rbp+10h]
  int v4; // [rsp+18h] [rbp+18h]

  for ( i = 32; ; --i )
  {
    result = x & (unsigned int)(1 << (i - 1));
    if ( result || i <= 1 )
      break;
  }
  v4 = 0;
  for ( j = 0; (unsigned int)j < i; j = (unsigned int)(j + 1) )
  {
    result = v4;
    if ( x & (1 << (i - j - 1)) )
      *(char *)(str + j) = 49;
    else
      *(char *)(str + j) = 48;
  }
  return result;
}

int main()
{
    char bin[32];
    unsigned int x;
    while (1){
        printf("Enter a decimal positive number: ");
        scanf("%u", &x);
        dec_to_bin(x, bin);
        printf("%d = %s\n\n", x, bin);
    }
	return 0;
}
