#!/usr/bin/perl -w
# Updated parser/formatter, that now targets pthread library instead
# Skeleton laid out, the printed lines will depend on what the final log file
# will look like.
use strict;
use warnings;

# Globals
my $timestamp;
my $callingThread;
my $enterExit;
my $functionName;
my $argumentList;
my $stackOrReturn;
my @arguments;
my %objects;
my $count;

sub Init {
	system('rm -fr img');
	mkdir 'img';
}

sub DrawLegend {
	print 'digraph {
		rankdir=LR
		node [shape=plaintext]
		subgraph cluster_01 {
		  label = "Legend";
		  key [label=<<table border="0" cellpadding="2" cellspacing="0" cellborder="0">
		    <tr><td align="right" port="i1">item 1</td></tr>
		    <tr><td align="right" port="i2">item 2</td></tr>
		    <tr><td align="right" port="i3">item 3</td></tr>
		    <tr><td align="right" port="i4">item 4</td></tr>
		    </table>>]
		  key2 [label=<<table border="0" cellpadding="2" cellspacing="0" cellborder="0">
		    <tr><td port="i1">&nbsp;</td></tr>
		    <tr><td port="i2">&nbsp;</td></tr>
		    <tr><td port="i3">&nbsp;</td></tr>
		    <tr><td port="i4">&nbsp;</td></tr>
		    </table>>]
		  key:i1:e -> key2:i1:w [style=dashed]
		  key:i2:e -> key2:i2:w [color=gray]
		  key:i3:e -> key2:i3:w [color=peachpuff3]
		  key:i4:e -> key2:i4:w [color=turquoise4, style=dotted]
		}
	}'
}

# TODO:
# This function should take an argument list and return the thread's id.
# 1. Parse the first argument in argument list, this is the address in memory
# of the thread's id.
# 2. Access the memory where the thread id is and return it.
# This may not be possible.. may have to find another way to get the thread id.
sub GetThreadID {
	# This will depend upon how the logfile lists the arguments
	#@arguments = split ',', $argumentList;
	# ...
	return $_;
}

sub WriteDOTFile {
	#Prints out to our DOT file progressively each line.
	open (GRAPHFILE, ">", "graph.dot");
	print GRAPHFILE "digraph G {\n";
	print GRAPHFILE "graph[page=\"8,10\"];\n";
	print GRAPHFILE "graph[center=1];\n";
	#print GRAPHFILE "graph[margin=\"2\"];\n";
	foreach my $key (keys %objects) {
		if ($objects{$key}{'Type'} eq "Thread") {
			if ($objects{$key}{'Status'} eq "Alive") {
				print GRAPHFILE "$key [shape=box,color=black];\n";
			}
			if ($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=box,color=lightgray];\n";
			}
			# break the joins into array after removing trailing commas
			$objects{$key}{'Joins'} = substr $objects{$key}{'Joins'}, 0, -1; 
			my @joinedThreads = split ',', $objects{$key}{'Joins'};
			foreach my $join (@joinedThreads) {
				print GRAPHFILE "$key -> $join [arrowhead=odot];\n";
			}
			# deals with printing out all edges for threads
			foreach my $linkKey (keys %{$objects{$key}{'Links'}}) {
				print GRAPHFILE "$key -> $linkKey";
				if ($objects{$key}{'Links'}{$linkKey} eq "child") {
					print GRAPHFILE " [arrowhead=normal];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "spinlock") {
					print GRAPHFILE " [arrowhead=diamond,color=black];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "spinunlocked") {
					print GRAPHFILE " [arrowhead=diamond,color=lightgray];\n";
				}	
				elsif ($objects{$key}{'Links'}{$linkKey} eq "lock") {
					print GRAPHFILE " [arrowhead=normal,color=black];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "unlocked") {
					print GRAPHFILE " [arrowhead=normal,color=lightgray];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "condlock") {
					print GRAPHFILE " [arrowhead=inv,color=black];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "condunlock") {
					print GRAPHFILE " [arrowhead=inv,color=lightgray];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "barrier") {
					print GRAPHFILE " [arrowhead=box,color=black];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "maxed barrier") {
					print GRAPHFILE " [arrowhead=box,color=lightgray];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "rdlock") {
					print GRAPHFILE " [arrowhead=dot,color=blue];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "wrlock") {
					print GRAPHFILE " [arrowhead=dot,color=red];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "rwunlocked") {
					print GRAPHFILE " [arrowhead=dot,color=lightgray];\n";
				}
			}
		}
		elsif ($objects{$key}{'Type'} eq "Spinlock") {
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=ellipse,color=black];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=ellipse,color=red];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=ellipse,color=lightgray]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Mutex") {
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=trapezium,color=black];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=trapezium,color=red];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=trapezium,color=lightgray]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Barrier") {
			if ($objects{$key}{'Status'} eq "Unused") {
				print GRAPHFILE "$key [shape=octagon,color=black];\n";
			}
			elsif($objects{$key}{'Status'} eq "Used") {
				print GRAPHFILE "$key [shape=octagon,color=red];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=octagon,color=lightgray]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "RWLock") {
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=invtriangle,color=black];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=invtriangle,color=red];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=invtriangle,color=lightgray]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Condition Variable") {
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=parallelogram,color=black];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=parallelogram,color=red];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=parallelogram,color=lightgray]\n";
			}
		}
	}
	print GRAPHFILE "}";
}

sub DrawPNG {
	# Pad number with leading zeros.
	my $num = sprintf("%03d", $_[0]);
	my $cmd = 'dot -Tpng graph.dot > img/output' . $num . '.png';
	system($cmd);
}

sub CreateGIF {
	system('convert -delay 100 -loop 0 img/output*.png img/view.gif');
}

&Init();
# All variable names currently temporary.
open (TIMESTAMPS, ">", "timestamps.txt");
open (LOGFILE, "logfile.txt") or die "Could not find specified logfile.";
$count = 1;
while (<LOGFILE>) {
	# Read a max of 100 lines
	if ($count == 100) {
		last;
	}
	chomp;
	# Splitting information in logfile by tab spaces
	($timestamp, $callingThread, $enterExit, $functionName, $argumentList, $stackOrReturn) = split(' ');
	# Chop off first and last characters
	$argumentList = substr substr($argumentList, 1), 0, -1;
	# Remove white spaces
	$argumentList =~ s/\s+//g;
	@arguments = split ',', $argumentList;
	# Logging the timestamps assuming that every line is a new thread state
	print TIMESTAMPS "Thread $callingThread Timestamp: $timestamp";

	# Scenarios for different functions. Assuming that all pthread calls will pass, besides the ones which waiti
	if ($functionName eq "pthread_join" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Joins'} = $objects{$callingThread}{'Joins'} . "$arguments[0],"
		}
	}
	elsif($functionName eq "pthread_create" && $enterExit eq "ENTER") {
		my %links;
		my @join;
		$objects{$arguments[0]} = {
			Type => 'Thread',
			Status => 'Alive',
			Joins => ' ',
			Links => \%links};
		if (exists $objects{$callingThread}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'child';
		}
		else {
			$objects{$callingThread} = {'Type' => 'Thread',
						    'Status' => 'Alive',
						    'Joins' => '',
						    'Links' => \%links};
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'child';
		}
	}
	elsif(($functionName eq "pthread_cancel") || ($functionName eq "pthread_exit") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}
	elsif($functionName eq "pthread_mutex_init" && $enterExit eq "ENTER") {
		$objects{$arguments[0]} = {'Type' => 'Mutex',
					   'Status' => 'Unlocked'};
	}
	elsif($functionName eq "pthread_mutex_lock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'lock';
		}
	}
	elsif($functionName eq "pthread_mutex_trylock" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
                        $objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'lock';
                }
	}
	elsif($functionName eq "pthread_mutex_unlock" && $enterExit eq "ENTER") {
		$objects{$callingThread}{'Status'} = 'Unlocked';
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'unlocked';
		}
	}	
	elsif($functionName eq "pthread_mutex_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}
	elsif($functionName eq "pthread_cond_init" && $enterExit eq "ENTER") {
		my @threads;
		$objects{$arguments[0]} = {'Type' => 'Condition Variable',
					   'Status' => 'Unlocked',
					   'Blocked Threads' => @threads};
	}
	elsif(($functionName eq "pthread_cond_wait" || $functionName eq "pthread_cond_timedwait") && $stackOrReturn eq "0" && $enterExit eq "Exit") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'condlock';
			$objects{$callingThread}{'Links'}{$arguments[1]} = 'lock';
		}	
	}
	#TODO: pthread_cond_signal not done, not sure how to show signal since it unblocks a random thread
	elsif($functionName eq "pthread_cond_broadcast" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			foreach my $thread (@{$objects{$arguments[0]}{'Blocked Threads'}}) {
				$objects{$thread}{'Links'}{$arguments[0]} = 'condunlock';
			}
		}
	}
	elsif($functionName eq "pthread_cond_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}
	elsif($functionName eq "pthread_barrier_init" && $enterExit eq "ENTER") {
		my @threads;
		$objects{$arguments[0]} = {'Type' => 'Barrier',
					   'Status' => 'Unused',
					   'Count' => 0,
					   'Max' => $arguments[2],
					   'Threads Waiting' => @threads};
	}
	elsif($functionName eq "pthread_barrier_wait" && $stackOrReturn eq "0" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			my @empty;
			$objects{$arguments[0]}{'Status'} = 'Used';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'barrier';
			$objects{$arguments[0]}{'Count'}++;
			push @{$objects{$arguments[0]}{'Threads Waiting'}}, $callingThread; 
			if ($objects{$arguments[0]}{'Count'} == $objects{$arguments[0]}{'Max'}) {
				$objects{$arguments[0]}{'Status'} = 'Unused';
				$objects{$arguments[0]}{'Count'} = 0;
				foreach my $thread (@{$objects{$arguments[0]}{'Threads Waiting'}}) {
					$objects{$callingThread}{'Links'}{$thread} = 'maxed barrier';
				}
				$objects{$arguments[0]}{'Threads Waiting'} = @empty;	 
			}
		}
	}
	elsif($functionName eq "pthread_barrier_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}
	elsif($functionName eq "pthread_spin_init" && $enterExit eq "ENTER") {
		$objects{$arguments[0]} = {'Type' => 'Spinlock',
					   'Status' => 'Unlocked'};
	}
	elsif($functionName eq "pthread_spin_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}
	elsif(($functionName eq "pthread_spin_lock" || $functionName eq "pthread_spin_trylock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'spinlock';
		}
	}
	elsif($functionName eq "pthread_spin_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'spinunlocked';
		}
	}
	elsif($functionName eq "pthread_rwlock_init" && $enterExit eq "ENTER") {
		$objects{$arguments[0]} = {'Type' => 'RWLock',
					   'Status' => 'Unlocked'};
	}
	#readlock, not differentiating between different locks atm
	elsif($functionName eq "pthread_rwlock_rdlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rdlock';
		}
	}
	elsif($functionName eq "pthread_rwlock_wrlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'wrlock';
		}
	}
	elsif(($functionName eq "pthread_rwlock_trywrlock" || $functionName eq "pthread_rwlock_timedrdlock") && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'wrlock';
		}	
	}
	elsif(($functionName eq "pthread_rwlock_tryrdlock" || $functionName eq "pthread_rwlock_timedwrlock") && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rdlock';
		}
	}
	elsif($functionName eq "pthread_rwlock_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rwunlocked';
		}
	}
	elsif($functionName eq "pthread_rwlock_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
	}

	&WriteDOTFile();
	&DrawPNG($count);
	$count++;
}

#&DrawLegend();
close (GRAPHFILE);
close (TIMESTAMPS);
close (LOGFILE);

&CreateGIF();
exit;
