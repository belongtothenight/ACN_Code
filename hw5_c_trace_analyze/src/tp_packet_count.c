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
#define CLI_MAX_INPUTS 7

/**
 * @brief Print help message
 */
void print_help_message (void);

/**
 * @brief Main function, parse trace file and extract packet count, and display to stdout
 * @param argc Argument count
 * @param argv Argument vector
 * @return Error code
 * @details
 * Normal usage: ./tp_packet_count -i <input_file> -t <time_interval> [-v]
 * Display help message: ./tp_packet_count -h
 */
int main (int argc, char *argv[]) {
    /* initialize */
    register_all_signal_handlers();

    /* params */
                errno = 0;          /* error number */
    ec_t        ec = 0;             /* error code */
    int         i;                  /* iterator */
    bool        verbose = false;    /* verbose output */
    char       *endptr;             /* string to double conversion pointer */
    const char *input_file = NULL;  /* input file */
    double      time_interval = 0;  /* time interval (sec) */

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
        if ((strcmp(argv[i], "-i") == 0) || (strcmp(argv[i], "--input") == 0)) {
            i++;
            if (i < argc) {
                input_file = argv[i];
            } else {
                ec = EC_CLI_NO_INPUT_FILE_VALUE;
            }
        } else if ((strcmp(argv[i], "-t") == 0) || (strcmp(argv[i], "--time-interval") == 0)) {
            i++;
            if (i < argc) {
                time_interval = strtod(argv[i], &endptr);
                /* 
                 * strtod error checking
                 * man strtod
                 * man 3 strtol
                 */
                if (errno != EC_SUCCESS) {
                    perror("strtod");
                    printf("errno = %d -> %s\n", errno, strerror(errno));
                    ec = EC_CLI_INVALID_TIME_INTERVAL;
                }
                if (endptr == argv[i]) {
                    printf("No digits were found\n");
                    ec = EC_CLI_INVALID_TIME_INTERVAL;
                }
            } else {
                ec = EC_CLI_NO_TIME_INTERVAL_VALUE;
            }
        /* Check for single arguments */
        } else if (strcmp(argv[i], "-h") == 0) {
            print_help_message();
            exit(EXIT_SUCCESS);
        } else if (strcmp(argv[i], "--help") == 0) {
            print_help_message();
            exit(EXIT_SUCCESS);
        } else if (strcmp(argv[i], "-v") == 0) {
            verbose = true;
        } else if (strcmp(argv[i], "--verbose") == 0) {
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
        printf("    Time interval:  %lf\n", time_interval);
    }

    /* check for required arguments */
    if (ec == EC_SUCCESS) {
        if (input_file == NULL) {
            ec = EC_CLI_NO_INPUT_OPTION;
        }
        if (time_interval <= 0) {
            ec = EC_CLI_NO_TIME_INTERVAL_OPTION;
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
        } else if (time_interval <= 1) {
            ec = EC_CLI_INVALID_TIME_INTERVAL;
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
    printf("Usage: ./tp_packet_count -i <input_file> -t <time_interval> [-v]\n");
    printf("       ./tp_packet_count -h\n");
    printf("Options:\n");
    printf("  -i, --input <input_file>              Input file\n");
    printf("  -t, --time-interval <time_interval>   Time interval (sec)\n");
    printf("  -v, --verbose                         Verbose output\n");
    printf("  -h, --help                            Display help message\n");
    return;
}
