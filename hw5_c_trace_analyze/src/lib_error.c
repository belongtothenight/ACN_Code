/*
 * @file lib_error.c
 * @brief Error handling library source file
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

#include <stdio.h>

#include "lib_output_format.h"
#include "lib_error.h"

void print_ec_message (ec_t ec) {
    output_format format;
    get_format(&format);
    switch (ec) {
        case 0:
            printf("%sSuccess\n", format.status.success);
            break;
        /* > 0x1000: CLI general errors */
        case EC_CLI_NO_INPUTS:
            printf("%s0x%x: No input CLI arguments provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_MAX_INPUTS:
            printf("%s0x%x: Too many input CLI arguments provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_UNKNOWN_OPTION:
            printf("%s0x%x: Unknown CLI option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_INPUT_FILE_NOT_FOUND:
            printf("%s0x%x: Input file not found\n\n", format.status.error, ec);
            break;
        /* > 0x1400: CLI input value missing errors */
        case EC_CLI_NO_INPUT_FILE_VALUE:
            printf("%s0x%x: No input file value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_QUANTIZE_TIME_VALUE:
            printf("%s0x%x: No quantize time value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_OUTPUT_FILE_VALUE:
            printf("%s0x%x: No output file value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_TIME_INTERVAL_VALUE:
            printf("%s0x%x: No time interval value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_COUNT_SIZE_VALUE:
            printf("%s0x%x: No count size value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_HISTOGRAM_PATH_VALUE:
            printf("%s0x%x: No histogram path value provided\n\n", format.status.error, ec);
            break;
        /* > 0x1800: CLI input option missing errors */
        case EC_CLI_NO_INPUT_OPTION:
            printf("%s0x%x: No \"-i\" or \"--input\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_QUANTIZE_TIME_OPTION:
            printf("%s0x%x: No \"-q\" or \"--quantize-time\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_OUTPUT_OPTION:
            printf("%s0x%x: No \"-o\" or \"--output\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_TIME_INTERVAL_OPTION:
            printf("%s0x%x: No \"-t\" or \"--time-interval\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_COUNT_SIZE_OPTION:
            printf("%s0x%x: No \"-c\" or \"--count-size\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_HISTOGRAM_PATH_OPTION:
            printf("%s0x%x: No \"-p\" or \"--histogram-path\" option provided\n\n", format.status.error, ec);
            break;
        /* > 0x1C00: CLI input value invalid errors */
        case EC_CLI_INVALID_INPUT_FILE:
            printf("%s0x%x: Invalid input file, should contains \".pcap\" in filename\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_QUANTIZE_TIME:
            printf("%s0x%x: Invalid quantize time, should provides valid integer number\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_OUTPUT_FILE:
            printf("%s0x%x: Invalid output file, should contains \".csv\" in filename\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_TIME_INTERVAL:
            printf("%s0x%x: Invalid time interval, should provides valid floating point number\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_COUNT_SIZE:
            printf("%s0x%x: Invalid count size, should provides valid integer number\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_HISTOGRAM_PATH:
            printf("%s0x%x: Invalid histogram path, should provides valid path\n\n", format.status.error, ec);
            break;
        /* > 0x2000: general errors */
        case EC_GEN_UNABLE_TO_CREATE_PACKET:
            printf("%s0x%x: Unable to create packet structure\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_CREATE_TRACE:
            printf("%s0x%x: Unable to create trace file\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_START_TRACE:
            printf("%s0x%x: Unable to start trace file\n\n", format.status.error, ec);
            break;
        case EC_GEN_TRACE_READ_PACKET_ERROR:
            printf("%s0x%x: Error occurred while reading packet from trace file\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_GET_TIMESPEC:
            printf("%s0x%x: Unable to get timespec\n\n", format.status.error, ec);
            break;
        case EC_GEN_CLOCK_GETTIME_ERROR:
            printf("%s0x%x: Error occurred while getting clock_gettime\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_USE_GNUPLOT:
            printf("%s0x%x: Unable to open gnuplot, please check your environment.\n\n", format.status.error, ec);
            break;
        case EC_GEN_GNUPLOT_ERROR:
            printf("%s0x%x: Error occurred while using gnuplot\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_OPEN_DATA_FILE:
            printf("%s0x%x: Unable to open data file at given path\n\n", format.status.error, ec);
            break;
        case EC_GEN_UNABLE_TO_WRITE_DATA_FILE:
            printf("%s0x%x: Unable to write data file\n\n", format.status.error, ec);
            break;
        /* > default: Unknown error code */
        default:
            printf("%sUnknown error code: 0x%x\n", format.status.error, ec);
            break;
    }
}
