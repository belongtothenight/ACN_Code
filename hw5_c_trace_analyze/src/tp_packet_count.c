#include <stdio.h>
#include "lib_output_format.h"
#include "lib_signal_handler.h"

int main (void) {
    register_all_signal_handlers();
    printf("Hello, world!\n");
}
