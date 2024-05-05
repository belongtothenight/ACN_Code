#ifndef LIB_ERROR_H
#define LIB_ERROR_H

/* Standard error codes */
#define EC_SUCCESS                      0x0000 /* Success */
#define EC_GENERAL_ERROR                0x0001 /* General error */

/* Internal error codes */
#define EC_CLI_NO_INPUTS                0x1001 /* No inputs provided to CLI */
#define EC_CLI_MAX_INPUTS               0x1002 /* Too many inputs provided to CLI */
#define EC_CLI_NO_INPUT_FILE_VALUE      0x1003 /* No value provided for input file */
#define EC_CLI_NO_BIN_COUNT_VALUE       0x1004 /* No value provided for input bin count */
#define EC_CLI_NO_OUTPUT_FILE_VALUE     0x1005 /* No value provided for output file */
#define EC_CLI_UNKNOWN_OPTION           0x1006 /* Unknown option provided to CLI */
#define EC_CLI_NO_INPUT_OPTION          0x1007 /* No option "-i" or "--input" provided to CLI */
#define EC_CLI_NO_BIN_COUNT_OPTION      0x1008 /* No option "-b" or "--bin-count" provided to CLI */
#define EC_CLI_NO_OUTPUT_OPTION         0x1009 /* No option "-o" or "--output" provided to CLI */
#define EC_CLI_INVALID_INPUT_FILE       0x100A /* Invalid input file */
#define EC_CLI_INVALID_BIN_COUNT        0x100B /* Invalid bin count */
#define EC_CLI_INVALID_OUTPUT_FILE      0x100C /* Invalid output file */
#define EC_CLI_INPUT_FILE_NOT_FOUND     0x100D /* Input file not found */

/**
 * @brief Error code
 */
typedef int ec_t;

/**
 * @brief Print error message with error code
 */
void print_ec_message (ec_t error_code);

#endif // LIB_ERROR_H
