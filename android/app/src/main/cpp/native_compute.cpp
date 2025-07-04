#include <cstdint>

extern "C" {

int32_t heavy_computation(int32_t input) {
    int32_t result = 1;
    for (int32_t i = 1; i <= input; ++i) {
        result *= i;
    }
    return result;
}

} 