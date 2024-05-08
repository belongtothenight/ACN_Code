/*
 * @file lib_error.h
 * @brief Error handling library
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

#ifndef LIB_ERROR_H
#define LIB_ERROR_H

/* Standard error codes */
#define EC_SUCCESS                          EXIT_SUCCESS /* Success */

/* Internal error codes */
/* > 0x1000: CLI general errors */
#define EC_CLI_NO_INPUTS                    0x1001 /* No inputs provided to CLI */
#define EC_CLI_MAX_INPUTS                   0x1002 /* Too many inputs provided to CLI */
#define EC_CLI_UNKNOWN_OPTION               0x1003 /* Unknown option provided to CLI */
#define EC_CLI_INPUT_FILE_NOT_FOUND         0x1004 /* Input file not found */
/* > 0x1400: CLI input value missing errors */
#define EC_CLI_NO_INPUT_FILE_VALUE          0x1401 /* No value provided for input file */
#define EC_CLI_NO_QUANTIZE_TIME_VALUE       0x1402 /* No value provided for quantize time */
#define EC_CLI_NO_OUTPUT_FILE_VALUE         0x1403 /* No value provided for output file */
#define EC_CLI_NO_TIME_INTERVAL_VALUE       0x1404 /* No value provided for time interval */
#define EC_CLI_NO_COUNT_SIZE_VALUE          0x1405 /* No value provided for count size */
#define EC_CLI_NO_HISTOGRAM_PATH_VALUE      0x1406 /* No value provided for histogram path */
/* > 0x1800: CLI input option missing errors */
#define EC_CLI_NO_INPUT_OPTION              0x1801 /* No option "-i" or "--input" provided to CLI */
#define EC_CLI_NO_QUANTIZE_TIME_OPTION      0x1802 /* No option "-q" or "--quantize-time" provided to CLI */
#define EC_CLI_NO_OUTPUT_OPTION             0x1803 /* No option "-o" or "--output" provided to CLI */
#define EC_CLI_NO_TIME_INTERVAL_OPTION      0x1804 /* No option "-t" or "--time-interval" provided to CLI */
#define EC_CLI_NO_COUNT_SIZE_OPTION         0x1805 /* No option "-c" or "--count-size" provided to CLI */
#define EC_CLI_NO_HISTOGRAM_PATH_OPTION     0x1806 /* No option "-p" or "--histogram-path" provided to CLI */
/* > 0x1C00: CLI input value invalid errors */
#define EC_CLI_INVALID_INPUT_FILE           0x1C01 /* Invalid input file */
#define EC_CLI_INVALID_QUANTIZE_TIME        0x1C02 /* Invalid quantize time */
#define EC_CLI_INVALID_OUTPUT_FILE          0x1C03 /* Invalid output file */
#define EC_CLI_INVALID_TIME_INTERVAL        0x1C04 /* Invalid time interval */
#define EC_CLI_INVALID_COUNT_SIZE           0x1C05 /* Invalid count size */
#define EC_CLI_INVALID_HISTOGRAM_PATH       0x1C06 /* Invalid histogram path */
/* > 0x2000: general errors */
#define EC_GEN_UNABLE_TO_CREATE_PACKET      0x2001 /* Unable to open trace file */
#define EC_GEN_UNABLE_TO_CREATE_TRACE       0x2002 /* Unable to create trace */
#define EC_GEN_UNABLE_TO_START_TRACE        0x2003 /* Unable to start trace */
#define EC_GEN_TRACE_READ_PACKET_ERROR      0x2004 /* Error in reading packet from trace */
#define EC_GEN_UNABLE_TO_GET_TIMESPEC       0x2005 /* Unable to get timespec */
#define EC_GEN_CLOCK_GETTIME_ERROR          0x2006 /* Error in clock_gettime */
#define EC_GEN_UNABLE_TO_USE_GNUPLOT        0x2007 /* Unable to use gnuplot */
#define EC_GEN_GNUPLOT_ERROR                0x2008 /* Error in gnuplot drawing process */
#define EC_GEN_UNABLE_TO_OPEN_DATA_FILE     0x2009 /* Unable to open data file */
#define EC_GEN_UNABLE_TO_WRITE_DATA_FILE    0x200A /* Unable to write data file */

/**
 * @brief Error code
 */
typedef int ec_t;

/**
 * @brief Print error message with error code
 */
void print_ec_message (ec_t error_code);

#endif // LIB_ERROR_H
