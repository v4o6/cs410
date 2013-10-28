#!usr/bin/perl
# Recursively checks all files in src directory for calls to the pthread
# library. Outputs a list of file names with relative paths to the $src
# directory. These files do not contain calls to pthread library functions.
# Author: Michael Zbeetnoff o8x7@ugrad.cs.ubc.ca
# October 27, 2013
#
# Usage:
# perl exclude.pl <src dir> <output-file>
use strict;
use warnings;

if (1 != $#ARGV) {
	print "Usage: perl exclude.pl <src-dir> <output-file>\n";
	die;
}
my $src = $ARGV[0];
my $out = $ARGV[1];
my @exclude = qw(
	pthread_create
	pthread_exit
	pthread_cancel
	pthread_attr_init
	pthread_attr_destroy);

# Finds all files with extensions .c and .cpp.
my $find = "find $src -name \"*.c\" -o -name \"*.cpp\"";
# Does a recursive grep of $src directory. Files not containing strings in
# @exclude array are listed in $out.
my $grep = "grep -rL -e" . join(" -e ", @exclude) . " > $out";
system($find . " | " . $grep);