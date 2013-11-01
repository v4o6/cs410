#!/usr/bin/perl
# Updated parser/formatter, that now targets pthread library instead
# Skeleton laid out, the printed lines will depend on what the final log file
# will look like.

#All variable names currently temporary
open (GRAPHFILE, ">", "graph.dot")
print GRAPHFILE "digraph G {\n";

open (TIMESTAMPS, ">", "timestamps.txt")

open (LOGFILE, "logfile.txt") or die "Could not find specified logfile.";
while (LOG<FILE>) {
	chomp;
	# Splitting information in logfile by tab spaces
	($timestamp, $threadNum, $enterExit, $functionName, $argumentList, $callStackTrace) = split("\t");
	# This will depend upon how the logfile lists the arguments
	@arguments = split ',', $argumentList;
	# Logging the timestamps assuming that every line is a new thread state
	print TIMESTAMPS "Thread $threadNum Timestamp: $timestamp";

	# Scenarios for different functions. More cases added depending on what we want to track
	if ($functionName eq "pthread_join") {
		
	}
	elsif ($functionName eq "pthread_create") {
		print GRAPHFILE "Thread$threadNum;\n"
	}
	elsif ($functionName eq "pthread_exit") {

	}
	elsif($functionName eq "pthread_cancel") {

	}
	elsif($functionName eq "pthread_mutex_lock") {
		
	}
}
print GRAPHFILE "\n}";
close (GRAPHFILE);
close (TIMESTAMPS);
close (LOGFILE);
exit;
