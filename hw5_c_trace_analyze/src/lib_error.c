#include <stdio.h>

#include "lib_output_format.h"
#include "lib_error.h"

void print_ec_message (ec_t ec) {
    output_format format;
    get_format(&format, 1);
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
        case EC_CLI_NO_BIN_COUNT_VALUE:
            printf("%s0x%x: No binary count value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_OUTPUT_FILE_VALUE:
            printf("%s0x%x: No output file value provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_TIME_INTERVAL_VALUE:
            printf("%s0x%x: No time interval value provided\n\n", format.status.error, ec);
            break;
        /* > 0x1800: CLI input option missing errors */
        case EC_CLI_NO_INPUT_OPTION:
            printf("%s0x%x: No \"-i\" or \"--input\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_BIN_COUNT_OPTION:
            printf("%s0x%x: No \"-b\" or \"--bincnt\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_OUTPUT_OPTION:
            printf("%s0x%x: No \"-o\" or \"--output\" option provided\n\n", format.status.error, ec);
            break;
        case EC_CLI_NO_TIME_INTERVAL_OPTION:
            printf("%s0x%x: No \"-t\" or \"--time-interval\" option provided\n\n", format.status.error, ec);
            break;
        /* > 0x1C00: CLI input value invalid errors */
        case EC_CLI_INVALID_INPUT_FILE:
            printf("%s0x%x: Invalid input file, should contains \".pcap\" in filename\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_BIN_COUNT:
            printf("%s0x%x: Invalid bin count, should provides valid integer number\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_OUTPUT_FILE:
            printf("%s0x%x: Invalid output file, should contains \".csv\" in filename\n\n", format.status.error, ec);
            break;
        case EC_CLI_INVALID_TIME_INTERVAL:
            printf("%s0x%x: Invalid time interval, should provides valid floating point number\n\n", format.status.error, ec);
            break;
        /* > default: Unknown error code */
        default:
            printf("%sUnknown error code: 0x%x\n", format.status.error, ec);
            break;
    }
}
