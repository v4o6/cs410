#include <stdio.h>
#include <pthread.h>

void* print(void *dummy) {
  printf("Hello from print.\n");
  
  return NULL;
}

int main() {
  pthread_t t;
  pthread_create(&t, NULL, print, NULL);
  pthread_join(t, NULL);

  return 0;
}
