#ifndef LIB_ERROR_H
#define LIB_ERROR_H

/* Standard error codes */
#define EC_SUCCESS                      EXIT_SUCCESS /* Success */

/* Internal error codes */
/* > 0x1000: CLI general errors */
#define EC_CLI_NO_INPUTS                0x1001 /* No inputs provided to CLI */
#define EC_CLI_MAX_INPUTS               0x1002 /* Too many inputs provided to CLI */
#define EC_CLI_UNKNOWN_OPTION           0x1003 /* Unknown option provided to CLI */
#define EC_CLI_INPUT_FILE_NOT_FOUND     0x1004 /* Input file not found */
/* > 0x1400: CLI input value missing errors */
#define EC_CLI_NO_INPUT_FILE_VALUE      0x1401 /* No value provided for input file */
#define EC_CLI_NO_BIN_COUNT_VALUE       0x1402 /* No value provided for input bin count */
#define EC_CLI_NO_OUTPUT_FILE_VALUE     0x1403 /* No value provided for output file */
#define EC_CLI_NO_TIME_INTERVAL_VALUE   0x1404 /* No value provided for time interval */
/* > 0x1800: CLI input option missing errors */
#define EC_CLI_NO_INPUT_OPTION          0x1801 /* No option "-i" or "--input" provided to CLI */
#define EC_CLI_NO_BIN_COUNT_OPTION      0x1802 /* No option "-b" or "--bin-count" provided to CLI */
#define EC_CLI_NO_OUTPUT_OPTION         0x1803 /* No option "-o" or "--output" provided to CLI */
#define EC_CLI_NO_TIME_INTERVAL_OPTION  0x1804 /* No option "-t" or "--time-interval" provided to CLI */
/* > 0x1C00: CLI input value invalid errors */
#define EC_CLI_INVALID_INPUT_FILE       0x1C01 /* Invalid input file */
#define EC_CLI_INVALID_BIN_COUNT        0x1C02 /* Invalid bin count */
#define EC_CLI_INVALID_OUTPUT_FILE      0x1C03 /* Invalid output file */
#define EC_CLI_INVALID_TIME_INTERVAL    0x1C04 /* Invalid time interval */

/**
 * @brief Error code
 */
typedef int ec_t;

/**
 * @brief Print error message with error code
 */
void print_ec_message (ec_t error_code);

#endif // LIB_ERROR_H
