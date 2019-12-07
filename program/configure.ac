#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([pdfgrader], [0.2], [lisaium@wwu.edu])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
PKG_CHECK_MODULES([pdfgrader], [
    gtk+-3.0
    poppler-glib
    cairo
    gee-0.8
    libxml-2.0
    glib-2.0

])




# Checks for programs.
AC_PROG_CC
AM_PROG_VALAC
PKG_PROG_PKG_CONFIG

# Checks for libraries.


# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES(Makefile)
AC_OUTPUT
