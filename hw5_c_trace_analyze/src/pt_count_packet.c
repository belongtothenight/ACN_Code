/*
 * @file tp_packet_count.c
 * @brief Count packet from trace file
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

/* System libraries */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <inttypes.h>

/* Public libraries */
#include "libtrace.h"

/* Project libraries */
#include "lib_output_format.h"
#include "lib_signal_handler.h"
#include "lib_error.h"

/* Constants */
#define CLI_MAX_INPUTS 7

/* Global variables */
uint64_t packet_count = 0;
time_t   next_interval_time_sec = 0;
long int next_interval_time_nsec = 0;

/**
 * @brief Print help message
 */
static void print_help_message (void);

/**
 * @brief Per-packet processing function, return 0 if success, otherwise return error code
 * @param packet Packet
 * @param time_interval Time interval
 * @return void
 */
static void per_packet (libtrace_packet_t *packet, double time_interval);

/**
 * @brief Main function, parse trace file and extract packet count, and display to stdout
 * @param argc Argument count
 * @param argv Argument vector
 * @return Error code
 * @details
 * Normal usage:            ./tp_count_packet -i <input_file> -t <time_interval> [-v]
 * Display help message:    ./tp_count_packet -h
 */
int main (int argc, char *argv[]) {
    /* params */
                        errno = 0;          /* error number */
    ec_t                ec = 0;             /* error code */
    int                 i;                  /* iterator */
    bool                verbose = false;    /* verbose output */
    char               *endptr;             /* string to double conversion pointer */
    const char         *input_file = NULL;  /* input file */
    double              time_interval = 0;  /* time interval (sec) */
    libtrace_t         *trace = NULL;       /* trace file */
    libtrace_packet_t  *packet = NULL;      /* packet */
    struct timespec     start_time;         /* start processing time */
    struct timespec     end_time;           /* end processing time */
    time_t              elapsed_time_sec;   /* elapsed time (sec) */
    long int            elapsed_time_nsec;  /* elapsed time (nsec) */

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
        } else if ((strcmp(argv[i], "-t") == 0) || (strcmp(argv[i], "--time-interval") == 0)) {
            i++;
            if (i < argc) {
                time_interval = strtod(argv[i], &endptr);
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
    if ((ec == EC_SUCCESS) && verbose) {
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
    if ((ec == EC_SUCCESS) && verbose) {
        printf("Required arguments checked\n");
    }

    /* check for valid arguments */
    if (ec == EC_SUCCESS) {
        if (strstr(input_file, ".pcap") == NULL) {
            /* Valid file types: https://github.com/LibtraceTeam/libtrace/blob/cc98f68f72e24bf51e2dabc00af0dbc4ffe7bb3d/lib/trace.c#L242 */
            ec = EC_CLI_INVALID_INPUT_FILE;
        } else if (time_interval <= 0) {
            ec = EC_CLI_INVALID_TIME_INTERVAL;
        }
        if (access(input_file, F_OK) != 0) {
            printf("File inaccessable: %s\n", input_file);
            ec = EC_CLI_INPUT_FILE_NOT_FOUND;
        }
    }
    if ((ec == EC_SUCCESS) && verbose) {
        printf("Valid arguments checked\n");
    }

    /* end of CLI argument parsing
     *
     * exit if there are any errors
     */
    if (ec != EC_SUCCESS) {
        print_ec_message(ec);
        print_help_message();
        exit(EXIT_FAILURE);
    }

    /* open trace file */
    if (ec == EC_SUCCESS) {
        packet = trace_create_packet();
        if (packet == NULL) {
            perror("trace_create_packet");
            ec = EC_GEN_UNABLE_TO_CREATE_PACKET;
        }
    }
    if (ec == EC_SUCCESS) {
        trace = trace_create(input_file);
        if (trace_is_err(trace)) {
            trace_perror(trace, "trace_create");
            ec = EC_GEN_UNABLE_TO_CREATE_TRACE;
        }
        if (trace_start(trace) != 0) {
            trace_perror(trace, "trace_start");
            ec = EC_GEN_UNABLE_TO_START_TRACE;
        }
    }
    if ((ec == EC_SUCCESS) && verbose) {
        printf("Trace file opened\n");
    }

    /* process trace file */
    printf("Processing trace file ...\n");
    if (ec == EC_SUCCESS) {
        if (clock_gettime(CLOCK_REALTIME, &start_time) == -1) {
            perror("clock_gettime");
            printf("errno = %d -> %s\n", errno, strerror(errno));
            ec = EC_GEN_CLOCK_GETTIME_ERROR;
        }
    }
    if (ec == EC_SUCCESS) {
        while (trace_read_packet(trace, packet) > 0) {
            per_packet(packet, time_interval);
        }
        if (trace_is_err(trace)) {
            /* only check for error after all file proccessed */
            trace_perror(trace, "Reading packets");
            ec = EC_GEN_TRACE_READ_PACKET_ERROR;
        }
    }
    if (ec == EC_SUCCESS) {
        if (clock_gettime(CLOCK_REALTIME, &end_time) == -1) {
            perror("clock_gettime");
            printf("errno = %d -> %s\n", errno, strerror(errno));
            ec = EC_GEN_CLOCK_GETTIME_ERROR;
        }
    }
    if (ec == EC_SUCCESS) {
        elapsed_time_sec = end_time.tv_sec - start_time.tv_sec;
        elapsed_time_nsec = end_time.tv_nsec - start_time.tv_nsec;
        if (elapsed_time_nsec < 0) {
            elapsed_time_sec--;
            elapsed_time_nsec += 1000000000;
        }
        printf("Elapsed time: %ld.%09ld sec\n", elapsed_time_sec, elapsed_time_nsec);
    }

    /* free resources */
    trace_destroy(trace);
    trace_destroy_packet(packet);

    /* exit */
    if (ec != EC_SUCCESS) {
        print_ec_message(ec);
        exit(EXIT_FAILURE);
    }
    printf("Program ended successfully!\n");
    exit(EXIT_SUCCESS);
}

static void print_help_message (void) {
    printf("Usage: ./tp_packet_count -i <input_file> -t <time_interval> [-v]\n");
    printf("       ./tp_packet_count -h\n");
    printf("Options:\n");
    printf("  -i, --input <input_file>              Input file\n");
    printf("  -t, --time-interval <time_interval>   Time interval (sec)\n");
    printf("  -v, --verbose                         Verbose output\n");
    printf("  -h, --help                            Display help message\n");
    return;
}

/* @brief per_packet function to process each packet 
 * @param packet Packet to process
 * @param time_interval Time interval
 * @return void
 * @details No error handling is done here as the error is already handled in the main function
 *          Also, if check is done here, excess CPU cycles will be used
 */
static void per_packet (libtrace_packet_t *packet, double time_interval) {
    /* params */
    struct timespec ts;                 /* timestamp */

    /* retrieve data from packet 
     *
     * https://github.com/LibtraceTeam/libtrace/blob/cc98f68f72e24bf51e2dabc00af0dbc4ffe7bb3d/lib/trace.c#L1438
     *
     * following line will result in -Waggregate-return warning
     * but it is safe to ignore as the struct is small and it is the intended practice
     */
    ts = trace_get_timespec(packet);

    /* first packet in trace 
     *
     * set next_interval_time_sec to the first time interval
     *
     * entire time = ts.tv_sec + ts.tv_nsec
     * https://en.cppreference.com/w/c/chrono/timespec
     */
    if (next_interval_time_sec == 0) {
        next_interval_time_sec = ts.tv_sec + (time_t) (time_interval);
        next_interval_time_nsec = ts.tv_nsec + (long int) ((time_interval - (time_t) time_interval) * 1000000000);
        printf("\nTime(Sec)\tTime(nSec)\tPackets\n");
    }

    /* When time interval is reached 
     *
     * Use while loop to ensure even if no packet is observed in the time interval
     */
    while (((time_t) ts.tv_sec > next_interval_time_sec) && ((long int) ts.tv_nsec > next_interval_time_nsec)) {
        printf("%lu \t%ld \t%" PRIu64 "\n", next_interval_time_sec, next_interval_time_nsec, packet_count);
        packet_count = 0;
        next_interval_time_sec += (time_t) (time_interval);
        next_interval_time_nsec += (long int) ((time_interval - (time_t) time_interval) * 1000000000);
        if (next_interval_time_nsec >= 1000000000) {
            next_interval_time_sec++;
            next_interval_time_nsec -= 1000000000;
        }
    }
    
    packet_count++;
    return;
}
