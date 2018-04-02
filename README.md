# removeCommonSubstrs.pl version 1.002
# ====================================

  What is it?
  -----------

  This takes a series of strings, splits them based on word boundaries, and removes portions of each string that are present in (by default) all strings.

## INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make install

And optionally (to remove unnecessary files):

    make clean

## RUNNING

To get the usage:

    removeCommonSubstrs.pl

To get a detailed usage:

    removeCommonSubstrs.pl --extended

To get help:

    removeCommonSubstrs.pl --help

Example run:

    >removeCommonSubstrs.pl common_1 common_2 common_3
    1
    2
    3

## DEPENDENCIES

This module comes with a pre-release version of a perl module called "CommandLineInterface".  CommandLineInterface requires these other modules and libraries:

  Getopt::Long
  File::Glob

## COPYRIGHT AND LICENCE

See LICENSE
