#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <errno.h>
#include <string.h>

// Error codes
int err_math = 0x1;
int err_overflow = 0x2;
int err_callback = 0x3;
int err_bad_args = 0x4;

const char* usage = "Usage: ./pow number power\n" \
                    "number - int32, power - uint32\n" \
                    "gibberish input is treated like value 0\n" \
                    "Example ./pow 2 3";

typedef int (*callback)(int);
extern int power(int32_t number, uint32_t power, callback cb);

int process_results(int x) 
{
    printf("Result: %d\n", x);
    return 0;
}

int main(int argc, char* argv[]) 
{
    // Check if arguments are passed
    if (argc != 3)
    {
        puts(usage);
        return err_bad_args;
    }

    // Convert arguments from strings to numbers
    int32_t num = (int32_t) strtoll(argv[1], NULL, 10);
    if (errno != 0)
    {
        fprintf(stderr, "%s\n", strerror(errno));
        return err_bad_args;
    }

    uint32_t pow = (uint32_t) strtoul(argv[2], NULL, 10);
    if (errno != 0)
    {
        fprintf(stderr, "%s\n", strerror(errno));
        return err_bad_args;
    }

    // Check if result is defined
    if (num == 0 && pow == 0)
    {
        fprintf(stderr, "Undefined: 0 power 0!\n");
        return err_math;
    }

    // Call power function
    int32_t ret_code = power(num, pow, process_results);

    // Check if it worked correctly
    if (ret_code == err_overflow)
    {
        fprintf(stderr, "Overflow!\n");
    }
    else if (ret_code == err_callback)
    {
        fprintf(stderr, "Failed to process results!\n");
    }

    return ret_code;
}