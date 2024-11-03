#include <stdint.h>

int32_t add(int32_t a, int32_t b) {
    return a + b;
}


int main() {
    int32_t a = 1;
    int32_t b = 2;
    int32_t c = add(a, b);
    return 0;
}