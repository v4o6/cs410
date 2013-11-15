#!/usr/bin/perl
# Updated parser/formatter, that now targets pthread library instead
# Skeleton laid out, the printed lines will depend on what the final log file
# will look like.
use strict;
use warnings;

# Globals
my @nodes = ();
my $timestamp;
my $threadNum;
my $enterExit;
my $functionName;
my $argumentList;
my $stackOrReturn;
my @arguments;

# Subroutine for parsing a line of logfile.txt, and pushing nodes as objects to
# the hash array @nodes.
sub ParseEvent {
	chomp;
	print $_;
}

#All variable names currently temporary
open (GRAPHFILE, ">", "graph.dot");
print GRAPHFILE "digraph G {\n";

open (TIMESTAMPS, ">", "timestamps.txt");
open (LOGFILE, "logfile.txt") or die "Could not find specified logfile.";
while (<LOGFILE>) {
	chomp;
	&ParseEvent();
}

	# Splitting information in logfile by tab spaces
		($timestamp, $threadNum, $enterExit, $functionName, $argumentList, $stackOrReturn) = split("\t");
	# This will depend upon how the logfile lists the arguments
	@arguments = split ',', $argumentList;
	# Logging the timestamps assuming that every line is a new thread state
	print TIMESTAMPS "Thread $threadNum Timestamp: $timestamp";

	# Scenarios for different functions. Assuming that all pthread calls will pass, besides the ones which wait
	if ($functionName eq "pthread_join" && $enterExit eq "Enter") {
		print GRAPHFILE "Thread$threadNum -> Thread$arguments[0] [arrowhead=odot]\n";	
	}
	elsif($functionName eq "pthread_create" && $enterExit eq "Enter") {
		print GRAPHFILE "Thread$threadNum -> Thread$arguments[0]\n";
	}
	elsif(($functionName eq "pthread_cancel") || ($functionName eq "pthread_exit") && $enterExit eq "Enter") {
		print GRAPHFILE "Thread$arguments[0] [color=lightgray]\n";
	}
	elsif($functionName eq "pthread_mutex_init" && $enterExit eq "Enter") {
		print GRAPHFILE "Mutex$arguments[0] [shape=diamond]\n";
	}
	elsif($functionName eq "pthread_mutex_lock" && $enterExit eq "Enter") {
		print GRAPHFILE "Mutex$arguments[0] [color=red]\nThread$threadNum -> Mutex$arguments[0]\n";
	}
	elsif($functionName eq "pthread_mutex_trylock" && $enterExit eq "Exit" && $stackOrReturn eq "0") {
		print GRAPHFILE "Mutex$arguments[0] [color=red]\nThread$threadNum -> Mutex$arguments[0]\n";
	}
	elsif($functionName eq "pthread_mutex_unlock" && $enterExit eq "Enter") {
		print GRAPHFILE "Mutex$arguments[0] [color=black]\nThread$threadNum ->Mutex$arguments[0] [color=lightgray]\n";
	}	
	elsif($functionName eq "pthread_mutex_destroy" && $enterExit eq "Enter") {
		print GRAPHFILE "Mutex$arguments[0] [color=lightgrey]\n";
	}
	elsif($functionName eq "pthread_cond_init" && $enterExit eq "Enter") {
		print GRAPHFILE "Condition$arguments[0] [shape=triangle]\n";
	}
	elsif(($functionName eq "pthread_cond_wait" || $functionName eq "pthread_cond_timedwait") && $stackOrReturn eq "0" && $enterExit eq "Exit") {
		print GRAPHFILE "Condition$arguments[0] -> Mutex$arguments[1]\nThread$threadNum -> Mutex$arguments[1]\nMutex$arguments[1] [color=red]\n";
	}
	#TODO: pthread_cond_signal and broadcast not done, not sure how to show signal since it unblocks a random thread
	elsif($functionName eq "pthread_cond_destroy" && $enterExit eq "Enter") {
		print GRAPHFILE "Condition$arguments[0] [color=lightgray]\n";
	}
	elsif($functionName eq "pthread_barrier_init" && $enterExit eq "Enter") {
		print GRAPHFILE "Barrier$arguments[0] [shape=octagon]\n";
	}
	#TODO: make a check if the correct # of threads are waiting
	elsif($functionName eq "pthread_barrier_wait" && $stackOrReturn eq "0" && $enterExit eq "Exit") {
		print GRAPHFILE "Thread$threadNum -> Barrier$arguments[0] [arrowhead=dot]\n";
	}
	elsif($functionName eq "pthread_barrier_destroy" && $enterExit eq "Enter") {
		print GRAPHFILE "Barrier$arguments[0] [color=lightgray]\n";
	}
	elsif($functionName eq "pthread_spin_init" && $enterExit eq "Enter") {
		print GRAPHFILE "Spinlock$arguments[0] [shape=circle]\n";
	}
	elsif($functionName eq "pthread_spin_destroy" && $enterExit eq "Enter") {
		print GRAPHFILE "Spinlock$arguments[0] [color=lightgray]\n";
	}
	elsif(($functionName eq "pthread_spin_lock" || $functionName eq "pthread_spin_trylock") && $enterExit eq "Enter") {
		print GRAPHFILE "Spinlock$arguments[0] [color=red]\nThread$threadNum -> Spinlock$arguments[0] [arrowhead=inv]\n";
	}
	elsif($functionName eq "pthread_spin_unlock" && $enterExit eq "Enter") {
		print GRAPHFILE "Thread$threadNum -> Spinlock$arguments[0] [color=lightgray]\nSpinlock$arguments[0] [color=black]\n";
	}
	elsif($functionName eq "pthread_rwlock_init" && $enterExit eq "Enter") {
		print GRAPHFILE "RWLock$arguments[0] [shape=doublecircle]\n";
	}
	#readlock, not differentiating between different locks atm
	elsif($functionName eq "pthread_rwlock_rdlock" && $enterExit eq "Enter") {
		print GRAPHFILE "RWLock$arguments[0] [color=red]\nThread$threadNum -> RWLock$arguments[0]\n";
	}
	elsif($functionName eq "pthread_rwlock_wrlock" && $enterExit eq "Enter") {
		print GRAPHFILE "RWLocK$arguments[0] [color=red]\nThread$threadNum -> RWLock$arguments[0]\n";
	}
	elsif(($functionName eq "pthread_rwlock_trywrlock" || $functionName eq "pthread_rwlock_timedrdlock") && $enterExit eq "Exit" && $stackOrReturn eq "0") {
		print GRAPHFILE "RWLocK$arguments[0] [color=red]\nThread$threadNum -> RWLock$arguments[0]\n";
	}
	elsif(($functionName eq "pthread_rwlock_tryrdlock" || $functionName eq "pthread_rwlock_timedwrlock") && $enterExit eq "Exit" && $stackOrReturn eq "0") {
		print GRAPHFILE "RWLock$arguments[0] [color=red]\nThread$threadNum -> RWLock$arguments[0]\n";
	}
	elsif($functionName eq "pthread_rwlock_unlock" && $enterExit eq "Enter") {
		print GRAPHFILE "Thread$threadNum -> RWLock$arguments[0] [color=lightgray]\nRWLock$arguments[0] [color=black]\n";
	}
	elsif($functionName eq "pthread_rwlock_destroy" && $enterExit eq "Enter") {
		print GRAPHFILE "RWLock$arguments[0] [color=lightgray]\n";
	}
}
print GRAPHFILE "\n}";
close (GRAPHFILE);
close (TIMESTAMPS);
close (LOGFILE);
exit;
