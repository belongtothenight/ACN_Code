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

# Checks for header files.
AC_CHECK_HEADERS([stdio.h stdlib.h stdbool.h string.h signal.h unistd.h errno.h])

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
AC_CHECK_FUNCS([setvbuf strcmp atoi printf exit strstr signal sizeof snprintf strdup access strtod perror strerror])

AC_CONFIG_FILES([Makefile
                 src/Makefile])
AC_OUTPUT
