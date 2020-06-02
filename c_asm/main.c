#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <errno.h>
#include <string.h>

// Error codes that power can return.
#define MATH_ERR 0x1
#define OVERFLOW 0x2
#define CALLBACK_ERR 0x3

typedef int (*callback)(int);

extern int power(int32_t number, uint32_t power, callback cb);

int process_results(int x) 
{
    printf("Result: %d\n", x);
    return 0;
}

const char* usage = "Usage: ./pow number power\n" \
                    "number - int32, power - uint32\n" \
                    "gibberish input is treated like value 0\n" \
                    "Example ./pow 2 3";

int main(int argc, char* argv[]) 
{
    // Check if arguments are passed
    if (argc != 3)
    {
        puts(usage);
        return 1;
    }

    // Convert arguments from strings to numbers
    errno = 0;
    int32_t num = (int32_t) strtoll(argv[1], NULL, 10);
    if (errno != 0)
    {
        printf("%s\n", strerror(errno));
    }

    uint32_t pow = (uint32_t) strtoul(argv[2], NULL, 10);
    if (errno != 0)
    {
        printf("%s\n", strerror(errno));
    }

    // Call power function
    int32_t ret_code = power(num, pow, process_results);

    // Check if it worked correctly
    if (ret_code == OVERFLOW)
    {
        puts("Overflow!");
    }
    else if (ret_code == MATH_ERR)
    {
        puts("Undefined: 0 power 0!");
    }
    else if (ret_code == CALLBACK_ERR)
    {
        puts("Failed to process results!");
    }

    return ret_code;
}