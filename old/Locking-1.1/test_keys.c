#include <stdio.h>
//#include <stdlib.h>
#include <sys/types.h>
//#include <sys/ipc.h>
//#include <sys/sem.h>
//#include <errno.h>
//#include <openssl/md5.h>

key_t string_to_key(char *string);

int main(){
  printf("%0X\n", string_to_key("lockin0"));
  printf("%0X\n", string_to_key("dgen0"));
  printf("%0X\n", string_to_key("3"));
  printf("%0X\n", string_to_key("4"));
  printf("%0X\n", string_to_key("5"));
  printf("%0X\n", string_to_key("6"));
  printf("%0X\n", string_to_key("7"));
  printf("%0X\n", string_to_key("8"));
  printf("%0X\n", string_to_key("29"));
  printf("%0X\n", string_to_key("30"));

  printf("%0X\n", string_to_key("31"));
  printf("%0X\n", string_to_key("32"));



}