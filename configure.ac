#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.57)
AC_INIT(chtml, 1.0, masud@googgun.com)
AM_INIT_AUTOMAKE([foreign])
AC_CONFIG_SRCDIR([chtml-lexer.l])
AC_CONFIG_HEADER([config.h])

# Checks for programs.
AC_PROG_CC

AM_PROG_LEX
# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST

# Checks for library functions.
AC_FUNC_REALLOC
AC_TYPE_SIGNAL
AC_FUNC_VPRINTF
AC_CHECK_FUNCS([strstr])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
