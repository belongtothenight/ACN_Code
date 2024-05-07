#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

# Versions
PROG_VER_MAJOR=1
PROG_VER_MINOR=0
PROG_VER_MICRO=0
PROG_VER_INFO_LIBTOOL=`expr $PROG_VER_MAJOR + $PROG_VER_MINOR`:$PROG_VER_MICRO:$PROG_VER_MINOR
USER_CFLAGS=$CFLAGS # save userspace CFLAGS options

AC_PREREQ([2.71])
AC_INIT([hello], [0.0.1], [dachuan516@gmail.com])
AC_SUBST([PROG_VER_INFO_LIBTOOL], [$PROG_VER_INFO_LIBTOOL])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects]) # Display all errors, treat warning as error, following minimum GNU policy, enable automake to look into subdirectories
AC_CONFIG_SRCDIR([src])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_PROG_AR

# Checks for programs.
AC_PROG_CC
LT_INIT([disable-static])

# Checks for libraries.
AC_CHECK_LIB([pthread], [pthread_mutex_trylock], [have_pthread=1], [have_pthread=0])
AC_CHECK_LIB([crypto], [OPENSSL_init_crypto], [have_crypto=1], [have_crypto=0])
AC_CHECK_LIB([wandder], [wandder_etsili_get_cc_format], [have_wandder=1], [have_wandder=0])
AC_CHECK_LIB([trace], [trace_create_packet], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_create], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_is_err], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_perror], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_start], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_read_packet], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_get_timespec], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_get_timeval], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_destroy], [have_trace=1], [have_trace=0])
AC_CHECK_LIB([trace], [trace_destroy_packet], [have_trace=1], [have_trace=0])

# Checks for header files.
AC_CHECK_HEADERS([stdio.h stdlib.h stdbool.h string.h signal.h unistd.h errno.h time.h inttypes.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T
AC_TYPE_INT8_T
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_UINT8_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_CHECK_FUNCS([access
                clock_gettime
                exit
                printf perror
                setvbuf strcmp strstr signal sizeof snprintf strdup strtod strtol strerror])

AC_CONFIG_FILES([Makefile
                 src/Makefile])
AC_SUBST([ADD_LIBS])
AC_SUBST([EXTRA_LIBS])
AC_SUBST([ADD_LDFLAGS])
AC_SUBST([ADD_INCLS])
AC_SUBST([LTLIBOBJS])
AC_OUTPUT
