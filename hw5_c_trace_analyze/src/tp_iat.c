// System libraries
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>

// Public libraries
#include "libtrace.h"

// Project libraries
#include "lib_output_format.h"
#include "lib_signal_handler.h"
#include "lib_error.h"

// Constants
#define CLI_MAX_INPUTS 8

/**
 * @brief Print help message
 */
void print_help_message (void);

/**
 * @brief Main function, parse trace file and extract IAT, then write to CSV file
 * @param argc Argument count
 * @param argv Argument vector
 * @return Error code
 * @details
 * Normal usage: ./tp_iat -i <input_file> -b <bin_count> -o <output_file> [-v]
 * Display help message: ./tp_iat -h
 */
int main (int argc, char *argv[]) {
    /* initialize */
    register_all_signal_handlers();

    /* params */
    ec_t        ec = 0;             /* error code */
    int         i;                  /* iterator */
    bool        verbose = false;    /* verbose output */
    const char *input_file = NULL;  /* input file */
    const char *output_file = NULL; /* output file */
    int         bin_count = 0;      /* number of bins */

    /* output may be going through pipe to log file */
    setvbuf(stdout, 0, _IONBF, 0);

    /* check CLI argument count */
    if (argc < 2) {
        ec = EC_CLI_NO_INPUTS;
    } else if (argc > CLI_MAX_INPUTS) {
        ec = EC_CLI_MAX_INPUTS;
    }

    /* parse CLI arguments */
    for (i=1 ; (i<argc) && (ec==0) ; i++) {
        /* Check for argument pairs */
        if (strcmp(argv[i], "-i") == 0) {
            i++;
            if (i < argc) {
                input_file = argv[i];
            } else {
                ec = EC_CLI_NO_INPUT_FILE_VALUE;
            }
        } else if (strcmp(argv[i], "--input") == 0) {
            i++;
            if (i < argc) {
                input_file = argv[i];
            } else {
                ec = EC_CLI_NO_INPUT_FILE_VALUE;
            }
        } else if (strcmp(argv[i], "-b") == 0) {
            i++;
            if (i < argc) {
                bin_count = atoi(argv[i]);
                if (bin_count == 0) {
                    ec = EC_CLI_INVALID_BIN_COUNT;
                }
            } else {
                ec = EC_CLI_NO_BIN_COUNT_VALUE;
            }
        } else if (strcmp(argv[i], "--bin-count") == 0) {
            i++;
            if (i < argc) {
                bin_count = atoi(argv[i]);
                if (bin_count == 0) {
                    ec = EC_CLI_INVALID_BIN_COUNT;
                }
            } else {
                ec = EC_CLI_NO_BIN_COUNT_VALUE;
            }
        } else if (strcmp(argv[i], "-o") == 0) {
            i++;
            if (i < argc) {
                output_file = argv[i];
            } else {
                ec = EC_CLI_NO_OUTPUT_FILE_VALUE;
            }
        } else if (strcmp(argv[i], "--output") == 0) {
            i++;
            if (i < argc) {
                output_file = argv[i];
            } else {
                ec = EC_CLI_NO_OUTPUT_FILE_VALUE;
            }
        /* Check for single arguments */
        } else if (strcmp(argv[i], "-h") == 0) {
            print_help_message();
            exit(EC_SUCCESS);
        } else if (strcmp(argv[i], "--help") == 0) {
            print_help_message();
            exit(EC_SUCCESS);
        } else if (strcmp(argv[i], "-v") == 0) {
            verbose = true;
        } else if (strcmp(argv[i], "--verbose") == 0) {
            verbose = true;
        } else {
            ec = EC_CLI_UNKNOWN_OPTION;
        }
    }
    if (verbose) {
        printf("Arguments parsed:\n");
        printf("Input file: \t%s\n", input_file);
        printf("Bin count: \t%d\n", bin_count);
        printf("Output file: \t%s\n", output_file);
    }

    /* check for required arguments */
    if (ec == 0) {
        if (input_file == NULL) {
            ec = EC_CLI_NO_INPUT_OPTION;
        } else if (bin_count == 0) {
            ec = EC_CLI_NO_BIN_COUNT_OPTION;
        } else if (output_file == NULL) {
            ec = EC_CLI_NO_OUTPUT_OPTION;
        }
        if (verbose) {
            printf("Required arguments check finished\n");
        }
    }

    /* check for valid arguments */
    if (ec == 0) {
        if (strstr(input_file, ".pcap") == NULL) {
            ec = EC_CLI_INVALID_INPUT_FILE;
        } else if (bin_count < 1) {
            ec = EC_CLI_INVALID_BIN_COUNT;
        } else if (strstr(output_file, ".csv") == NULL) {
            ec = EC_CLI_INVALID_OUTPUT_FILE;
        }
        if (access(input_file, F_OK) != 0) {
            printf("File inaccessable: %s\n", input_file);
            ec = EC_CLI_INPUT_FILE_NOT_FOUND;
        }
        if (verbose) {
            printf("Valid arguments check finished\n");
        }
    }
    if (ec != 0) {
        print_ec_message(ec);
        print_help_message();
        exit(ec);
    }

    /* main process */
    while (1) {
        printf("Hello, world!\n");
        sleep(1);
    }
}

void print_help_message (void) {
    printf("Usage: tp_iat -i <input_file> -b <bin count> -o <output_file> -v\n");
    printf("       tp_iat -h\n");
    printf("Options:\n");
    printf("  -i, --input       Input file\n");
    printf("  -b, --bin-count   Number of bins\n");
    printf("  -o, --output      Output csv file\n");
    printf("  -v, --verbose     Display verbose output\n");
    printf("  -h, --help        Display this help message\n");
    return;
}
