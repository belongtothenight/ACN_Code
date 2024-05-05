/**
 * @file lib_signal_handler.h
 * @brief Defines custom signal handler.
 * @author belongtothenight / Da-Chuan Chen / 2024
 * Ref:
 * 1. https://stackoverflow.com/questions/554138/catching-segfaults-in-c
 * 2. https://linuxhint.com/signal_handlers_c_programming_language/
 * 3. https://phoenixnap.com/kb/sigsegv
 * 4. https://www.ibm.com/docs/en/aix/7.2?topic=management-process-termination
 * 5. https://chromium.googlesource.com/chromiumos/docs/+/master/constants/signals.md
 * 6. https://stackoverflow.com/questions/16509614/signal-number-to-name
 * 7. https://openbooks.sourceforge.net/books/wga/dealing-with-libraries.html
*/

#ifndef SIGNAL_HANDLER_H
#define SIGNAL_HANDLER_H

#include <signal.h>

/**
 * @brief Signal handler for all signals.
 * @param signum:   int
 * @return void
 */
void signal_handler (int signum);

/**
 * @brief Register all signal handlers.
 * @return void
*/
void register_all_signal_handlers (void);

#endif // SIGNAL_HANDLER_H
