/*
 * @file tp_iat.c
 * @brief Main function, parse trace file and extract IAT, then write to CSV file
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

// System libraries
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

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
 * Normal usage:            ./tp_iat -i <input_file> -b <bin_count> -o <output_file> [-v]
 * Display help message:    ./tp_iat -h
 */
int main (int argc, char *argv[]) {
    /* params */
                errno = 0;          /* error number */
    ec_t        ec = 0;             /* error code */
    int         i;                  /* iterator */
    bool        verbose = false;    /* verbose output */
    char       *endptr;             /* string to int conversion pointer */
    const char *input_file = NULL;  /* input file */
    const char *output_file = NULL; /* output file */
    int         bin_count = 0;      /* number of bins */

    /* initialize */
    register_all_signal_handlers();
    if (errno != EC_SUCCESS) {
        perror("signal");
        printf("errno = %d -> %s\n", errno, strerror(errno));
        exit(EXIT_FAILURE);
    }
    ec = setvbuf(stdout, 0, _IONBF, 0); /* output may be going through pipe to log file */
    if ((ec != EC_SUCCESS) || (errno != EC_SUCCESS)) {
        perror("setvbuf");
        printf("errno = %d -> %s\n", errno, strerror(errno));
        exit(EXIT_FAILURE);
    }

    /* check CLI argument count */
    if (argc < 2) {
        ec = EC_CLI_NO_INPUTS;
    } else if (argc > CLI_MAX_INPUTS) {
        ec = EC_CLI_MAX_INPUTS;
    }

    /* parse CLI arguments */
    for (i=1 ; (i<argc) && (ec==0) ; i++) {
        /* Check for argument pairs */
        if ((strcmp(argv[i], "-i") == 0) || (strcmp(argv[i], "--input") == 0)) {
            i++;
            if (i < argc) {
                input_file = argv[i];
            } else {
                ec = EC_CLI_NO_INPUT_FILE_VALUE;
            }
        } else if ((strcmp(argv[i], "-b") == 0) || (strcmp(argv[i], "--bin-count") == 0)) {
            i++;
            if (i < argc) {
                bin_count = (int) strtol(argv[i], &endptr, 10);
                if (errno != EC_SUCCESS) {
                    perror("strtol");
                    printf("errno = %d -> %s\n", errno, strerror(errno));
                    ec = EC_CLI_INVALID_BIN_COUNT;
                }
                if (endptr == argv[i]) {
                    printf("No digits were found\n");
                    ec = EC_CLI_INVALID_BIN_COUNT;
                }
            } else {
                ec = EC_CLI_NO_BIN_COUNT_VALUE;
            }
        } else if ((strcmp(argv[i], "-o") == 0) || (strcmp(argv[i], "--output") == 0)) {
            i++;
            if (i < argc) {
                output_file = argv[i];
            } else {
                ec = EC_CLI_NO_OUTPUT_FILE_VALUE;
            }
        /* Check for single arguments */
        } else if ((strcmp(argv[i], "-h") == 0) || (strcmp(argv[i], "--help") == 0)) {
            print_help_message();
            exit(EXIT_SUCCESS);
        } else if ((strcmp(argv[i], "-v") == 0) || (strcmp(argv[i], "--verbose") == 0)) {
            verbose = true;
        } else {
            ec = EC_CLI_UNKNOWN_OPTION;
        }
        if (ec != EC_SUCCESS) {
            break;
        }
    }
    if (verbose) {
        printf("Arguments parsed:\n");
        printf("    Input file:     %s\n", input_file);
        printf("    Bin count:      %d\n", bin_count);
        printf("    Output file:    %s\n", output_file);
    }

    /* check for required arguments */
    if (ec == EC_SUCCESS) {
        if (input_file == NULL) {
            ec = EC_CLI_NO_INPUT_OPTION;
        } else if (bin_count == 0) {
            ec = EC_CLI_NO_BIN_COUNT_OPTION;
        } else if (output_file == NULL) {
            ec = EC_CLI_NO_OUTPUT_OPTION;
        }
    }
    if (ec == EC_SUCCESS) {
        if (verbose) {
            printf("Required arguments check finished\n");
        }
    }

    /* check for valid arguments */
    if (ec == EC_SUCCESS) {
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
    }
    if (ec == EC_SUCCESS) {
        if (verbose) {
            printf("Valid arguments check finished\n");
        }
    }

    if (ec != EC_SUCCESS) {
        print_ec_message(ec);
        print_help_message();
        exit(EXIT_FAILURE);
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
