/*
 * @file pt_quantize_iat.c
 * @brief Main function, parse trace file and extract IAT, 
 *        quantize them by time duration, then write count of each category into a PNG histogram
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

/* System libraries */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <inttypes.h>
#include <time.h>
#include <sys/time.h>

/* Public libraries */
#include "libtrace.h"

/* Project libraries */
#include "lib_output_format.h"
#include "lib_signal_handler.h"
#include "lib_error.h"

/* Constants */
#define CLI_MAX_INPUTS 11

/* Global variables */
time_t      next_interval_time_sec = 0;
time_t      initial_time_sec = 0;
suseconds_t initial_time_usec = 0;
time_t      current_time_sec = 0;
suseconds_t current_time_usec = 0;
time_t      iat_sec = 0;
suseconds_t iat_usec = 0;
long int    quantized_iat = 0;
uint64_t    negtive_iat_count = 0;      /* count of negtive IAT */
uint64_t    exceed_max_iat_count = 0;   /* count of IAT exceed max quantized IAT (IAT >= 2^quantized_time_order*iat_count_size+1) */
uint64_t   *quantized_iat_count = NULL; /* count of quantized IAT, dynamically allocated */

/**
 * @brief Print help message
 */
void print_help_message (void);

/**
 * @brief Per-packet processing function, return 0 if success, otherwise return error code
 * @param packet Packet
 * @param time_interval Time interval
 * @param quantize_time_order Quantize time order of 2
 * @param iat_count_size Size of quantized_iat_count
 * @return void
 */
static void per_packet (libtrace_packet_t *packet, double time_interval, uint64_t quantize_time_order, uint64_t iat_count_size);

/**
 * @brief Main function, parse trace file and extract IAT, then write to CSV file
 * @param argc Argument count
 * @param argv Argument vector
 * @return Error code
 * @details
 * Normal usage:            ./pt_quantize_iat -i <input_file> -q <quantize_time_order_of_2> [-s <iat_count_size>] [-p <path_of_histogram>] [-l] [-v]
 * Display help message:    ./pt_quantize_iat -h
 */
int main (int argc, char *argv[]) {
    /* params */
                        errno = 0;                      /* error number */
    ec_t                ec = 0;                         /* error code */
    int                 i;                              /* iterator */
    char               *endptr;                         /* string to int conversion pointer */
    double              time_interval = 10;             /* progress display time interval (sec) */
    libtrace_t         *trace = NULL;                   /* trace file */
    libtrace_packet_t  *packet = NULL;                  /* packet */
    struct timespec     start_time;                     /* start processing time */
    struct timespec     end_time;                       /* end processing time */
    time_t              elapsed_time_sec;               /* elapsed time (sec) */
    long int            elapsed_time_nsec;              /* elapsed time (nsec) */
    FILE               *gnuplot = NULL;                 /* gnuplot pipe */
    char                filename_buf[1024];             /* filename buffer */
    FILE               *data_file = NULL;               /* data file */
    const char         *input_file = NULL;              /* input file */
    uint64_t            quantize_time_order = 0;        /* quantize time order of 2 */
    uint64_t            iat_count_size = 20;            /* size of quantized_iat_count */
    const char         *histogram_path = NULL;          /* path of histogram */
    bool                histogram_log_scale = false;    /* histogram log scale */
    bool                verbose = false;                /* verbose output */

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
        } else if ((strcmp(argv[i], "-q") == 0) || (strcmp(argv[i], "--quantize-time") == 0)) {
            i++;
            if (i < argc) {
                /* following line will result in a -Wsign-conversion warning, from signed to unsigned
                 * but it is safe to ignore since the value should always be positive
                 */
                quantize_time_order = (long int) strtol(argv[i], &endptr, 10);
                if (errno != EC_SUCCESS) {
                    perror("strtol");
                    ec = EC_CLI_INVALID_QUANTIZE_TIME;
                }
                if (endptr == argv[i]) {
                    printf("No digits were found\n");
                    ec = EC_CLI_INVALID_QUANTIZE_TIME;
                }
            } else {
                ec = EC_CLI_NO_QUANTIZE_TIME_VALUE;
            }
        /* Check for optional arguments */
        } else if ((strcmp(argv[i], "-s") == 0) || (strcmp(argv[i], "--count-size") == 0)) {
            i++;
            if (i < argc) {
                /* following line will result in a -Wsign-conversion warning, from signed to unsigned
                 * but it is safe to ignore since the value should always be positive
                 */
                iat_count_size = (long int) strtol(argv[i], &endptr, 10);
                if (errno != EC_SUCCESS) {
                    perror("strtol");
                    ec = EC_CLI_INVALID_COUNT_SIZE;
                }
                if (endptr == argv[i]) {
                    printf("No digits were found\n");
                    ec = EC_CLI_INVALID_COUNT_SIZE;
                }
            } else {
                ec = EC_CLI_NO_COUNT_SIZE_VALUE;
            }
        } else if ((strcmp(argv[i], "-p") == 0) || (strcmp(argv[i], "--histogram-path") == 0)) {
            i++;
            if (i < argc) {
                histogram_path = argv[i];
            } else {
                ec = EC_CLI_NO_HISTOGRAM_PATH_VALUE;
            }
        /* Check for optional single arguments */
        } else if ((strcmp(argv[i], "-h") == 0) || (strcmp(argv[i], "--help") == 0)) {
            print_help_message();
            exit(EXIT_SUCCESS);
        } else if ((strcmp(argv[i], "-v") == 0) || (strcmp(argv[i], "--verbose") == 0)) {
            verbose = true;
        } else if ((strcmp(argv[i], "-l") == 0) || (strcmp(argv[i], "--log-scale") == 0)) {
            histogram_log_scale = true;
        } else {
            ec = EC_CLI_UNKNOWN_OPTION;
            printf("Unknown option: %s\n", argv[i]);
        }
        if (ec != EC_SUCCESS) {
            break;
        }
    }
    if ((ec == EC_SUCCESS) && verbose) {
        printf("Arguments parsed:\n");
        printf("    Input file:     %s\n", input_file);
        printf("    Quantize time:  %ld\n", quantize_time_order);
        printf("    Count size:     %ld\n", iat_count_size);
        printf("    Histogram path: %s\n", histogram_path);
    }

    /* check for required arguments */
    if (ec == EC_SUCCESS) {
        if (input_file == NULL) {
            ec = EC_CLI_NO_INPUT_OPTION;
        } else if (quantize_time_order == 0) {
            ec = EC_CLI_NO_QUANTIZE_TIME_OPTION;
        }
    }
    if ((ec == EC_SUCCESS) && verbose) {
        printf("Required arguments checked\n");
    }

    /* check for valid arguments */
    if (ec == EC_SUCCESS) {
        if (strstr(input_file, ".pcap") == NULL) {
            ec = EC_CLI_INVALID_INPUT_FILE;
        } else if (quantize_time_order < 1) {
            ec = EC_CLI_INVALID_QUANTIZE_TIME;
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
        printf("errno = %d -> %s\n", errno, strerror(errno));
        print_ec_message(ec);
        print_help_message();
        exit(EXIT_FAILURE);
    }

    /* open trace file */
    quantized_iat_count = (uint64_t *) malloc(iat_count_size * sizeof(uint64_t));
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
    if (ec == EC_SUCCESS) {
        printf("Processing trace file ...\n");
        if (clock_gettime(CLOCK_REALTIME, &start_time) == -1) {
            perror("clock_gettime");
            ec = EC_GEN_CLOCK_GETTIME_ERROR;
        }
    }
    if (ec == EC_SUCCESS) {
        while (trace_read_packet(trace, packet) > 0) {
            per_packet(packet, time_interval, quantize_time_order, iat_count_size);
        }
        exceed_max_iat_count--; /* remove error count caused by first packet */
        printf("\n");
        if (trace_is_err(trace)) {
            /* only check for error after all file proccessed */
            trace_perror(trace, "Reading packets");
            ec = EC_GEN_TRACE_READ_PACKET_ERROR;
        }
    }
    if (ec == EC_SUCCESS) {
        if (clock_gettime(CLOCK_REALTIME, &end_time) == -1) {
            perror("clock_gettime");
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
    if (ec == EC_SUCCESS) {
        for (i=0; i<(int) iat_count_size; i++) {
            printf("Quantized IAT[%02d]: %ld\n", i, quantized_iat_count[i]);
        }
    }

    /* free trace resources */
    trace_destroy(trace);
    trace_destroy_packet(packet);

    /* write count to dat file */
    if ((ec == EC_SUCCESS) && (histogram_path != NULL)) {
        snprintf(filename_buf, sizeof(filename_buf), "%s.dat", histogram_path);
        data_file = fopen(filename_buf, "w");
        if ((data_file == NULL) || ferror(data_file)) {
            perror("fopen");
            ec = EC_GEN_UNABLE_TO_OPEN_DATA_FILE;
        }
    }
    if ((ec == EC_SUCCESS) && (histogram_path != NULL)) {
        for (i=0; i<(int) iat_count_size; i++) {
            fprintf(data_file, "%ld\n", quantized_iat_count[i]);
        }
        if ((errno != EC_SUCCESS) && errno != EIO) {
            perror("fprintf");
            ec = EC_GEN_UNABLE_TO_WRITE_DATA_FILE;
        }
        if (errno == EIO) {
            perror("fprintf");
            printf("It is expected to have frequent EIO error in WSL2\n");
        }
    }
    if (ec == EC_SUCCESS) {
        printf("Histogram data written to %s\n", filename_buf);
    }
    /* write histogram file 
     *
     * https://gnuplot.sourceforge.net/demo/histograms.html
     * http://www.gnuplot.info/docs/loc5395.html
     */
    if ((ec == EC_SUCCESS) && (histogram_path != NULL)) {
        gnuplot = popen("gnuplot -persist", "w");
        if (gnuplot == NULL) {
            perror("popen");
            ec = EC_GEN_UNABLE_TO_USE_GNUPLOT;
        }
        fprintf(gnuplot, "set terminal pngcairo font \"%s,%d\" size %d,%d\n", "Arial", 20, 1920, 1080);
        fprintf(gnuplot, "set output \"%s.png\"\n", histogram_path);
        fprintf(gnuplot, "set title \"Histogram of Quantized IAT\"\n");
        fprintf(gnuplot, "set xlabel \"Quantized IAT\"\n");
        if (histogram_log_scale) {
            fprintf(gnuplot, "set ylabel \"Count (log-scaled)\"\n");
        } else {
            fprintf(gnuplot, "set ylabel \"Count\"\n");
        }
        fprintf(gnuplot, "set boxwidth 0.9 absolute\n");
        fprintf(gnuplot, "set style fill solid 1.00 border lt -1\n");
        fprintf(gnuplot, "set key fixed right top vertical Right noreverse noenhanced autotitle nobox\n");
        fprintf(gnuplot, "set style histogram clustered gap 1 title textcolor lt -1\n");
        fprintf(gnuplot, "set datafile missing '-'\n");
        fprintf(gnuplot, "set style data histograms\n");
        fprintf(gnuplot, "set xrange [-1:%d] noreverse writeback\n", (int) iat_count_size + 1);
        if (histogram_log_scale) {
            fprintf(gnuplot, "set logscale y\n");
        }
        fprintf(gnuplot, "plot newhistogram, '%s' using 1\n", filename_buf);
        //if (ferror(gnuplot)) { // debug - gnuplot will definitely show error message in this case
        if (ferror(gnuplot) || ((errno != 0) && (errno != EIO))) { // often errno is 5
            perror("fprintf");
            ec = EC_GEN_GNUPLOT_ERROR;
        }
        if (errno == EIO) {
            perror("fprintf");
            printf("It is expected to have frequent EIO error in WSL2\n");
        }
    }
    if (ec == EC_SUCCESS) {
        printf("Histogram file written to %s.png\n", histogram_path);
    }

    /* free memory */
    if (data_file != NULL) {
        fclose(data_file);
    }
    if (gnuplot != NULL) {
        pclose(gnuplot);
    }
    free(quantized_iat_count);

    /* exit */
    if (ec != EC_SUCCESS) {
        printf("errno = %d -> %s\n", errno, strerror(errno));
        print_ec_message(ec);
        exit(EXIT_FAILURE);
    }
    printf("Program ended successfully!\n");
    exit(EXIT_SUCCESS);
}

void print_help_message (void) {
    printf("Usage: pt_quantize_iat -i <input_file> -q <quantize_time> [-s <count_size>] [-p <path_of_histogram>] [-l] [-v]\n");
    printf("       pt_quantize_iat -h\n");
    printf("Options:\n");
    printf("  -i, --input           Input file\n");
    printf("  -q, --quantize-time   Time interval to quantize the packets, 2 to the power of t micro second\n");
    printf("  -s, --count-size      (optional) Number of quantized IAT to count, default=20, correspond to -q=4 or 5\n");
    printf("  -p, --histogram-path  (optional) Path to save the histogram file, export if specified. Require gnuplot. Do not include file extension\n");
    printf("  -l, --log-scale       (optional) Logarithmic scale for y-axis\n");
    printf("  -v, --verbose         (optional )Display verbose output\n");
    printf("  -h, --help            Display this help message\n");
    return;
}

/* @brief per_packet function to process each packet 
 * @param packet Packet to process
 * @param time_interval Time interval to update the processing progress
 * @param quantize_time_order Time interval to quantize the packets, 2 to the power of t microsecond
 * @param iat_count_size Number of quantized IAT to count
 * @return void
 * @details No error handling is done here as the error is already handled in the main function
 *          Also, if check is done here, excess CPU cycles will be used
 */
static void per_packet (libtrace_packet_t *packet, double time_interval, uint64_t quantize_time_order, uint64_t iat_count_size) {
    /* params */
    struct timeval ts;                  /* timestamp */

    /* retrieve data from packet 
     *
     * since IAT in practice only have microsecond precision, use timeval instead of timespec
     *
     * https://github.com/LibtraceTeam/libtrace/blob/cc98f68f72e24bf51e2dabc00af0dbc4ffe7bb3d/lib/trace.c#L1399
     *
     * following line will result in -Waggregate-return warning
     * but it is safe to ignore as the struct is small and it is the intended practice
     */
    ts = trace_get_timeval(packet);

    /* first packet in trace 
     *
     * set next_interval_time_sec to the first time interval
     *
     * set initial_time_sec to the first time interval
     */
    if (next_interval_time_sec == 0) {
        next_interval_time_sec = ts.tv_sec + (time_t) (time_interval);
        initial_time_sec = ts.tv_sec;
        initial_time_usec = ts.tv_usec;
    }

    /* When time interval is reached, display the processing progress
     *
     * Use while loop to ensure even if no packet is observed in the time interval
     *
     * the initial packet will add exceed_max_iat_count by 1, so subtract 1,
     * unsigned variable is used to contain the most amount of packets, so initialize with -1 doesn't work
     * instead of adding logic to skip the first packet, which will be processed in every packet
     */
    while ((time_t) ts.tv_sec > next_interval_time_sec) {
        printf("\33[2K\rProcessed %lu seconds of packets", ts.tv_sec - initial_time_sec);
        next_interval_time_sec += (time_t) (time_interval);
        printf("\t| negative IAT: %lu\t| exceed max IAT: %lu", negtive_iat_count, exceed_max_iat_count-1);
    }

    /* IAT calculation 
     *
     * use previously stored time to calculate the IAT, and store the current time
     *
     * no need to check for iat_sec is negative
     *
     * unify iat time to microseconds (iat_usec) for easier processing
     */
    if (next_interval_time_sec != 0) {
        iat_sec = ts.tv_sec - current_time_sec;
        iat_usec = ts.tv_usec - current_time_usec;
        iat_usec += iat_sec * 1000000;
    }
    current_time_sec = ts.tv_sec;
    current_time_usec = ts.tv_usec;

    /* quantize the IAT 
     *
     * also count the negative and max value exceed IAT
     */
    if (iat_usec < 0) {
        negtive_iat_count++;
        return;
    }
    quantized_iat = iat_usec >> quantize_time_order;
    if ((uint64_t) quantized_iat > iat_count_size) {
        exceed_max_iat_count++;
        return;
    }
    quantized_iat_count[quantized_iat]++;
    //printf("IAT: 0.%.06lu -> %lu\n", iat_usec, quantized_iat); // debug
    
    return;
}
