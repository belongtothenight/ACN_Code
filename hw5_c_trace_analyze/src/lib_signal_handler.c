/*
 * @file lib_signal_handler.c
 * @brief Signal handler library source file
 * @author belongtothenight / Da-Chuan Chen / 2024
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include "lib_signal_handler.h"
#include "lib_output_format.h"

void signal_handler (int signum) {
    output_format format;
    get_format(&format);
    char *signal_name = strsignal(signum);
    printf("\n%sSignal %2d -> %s received.\n", format.status.warning, signum, signal_name);
    exit(signum);
    return;
}

void register_all_signal_handlers (void) {
    // signal(SIGHUP, signal_handler);
    signal(SIGINT, signal_handler);
    // signal(SIGQUIT, signal_handler);
    signal(SIGILL, signal_handler);
    // signal(SIGTRAP, signal_handler);
    signal(SIGABRT, signal_handler);
    signal(SIGFPE, signal_handler);
    signal(SIGSEGV, signal_handler);
    signal(SIGTERM, signal_handler);
    return;
}
