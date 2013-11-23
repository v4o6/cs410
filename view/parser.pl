#!/usr/bin/perl -w
# Updated parser/formatter, that now targets pthread library instead
# Skeleton laid out, the printed lines will depend on what the final log file
# will look like.
use strict;
use warnings;
use Data::Dumper;

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
my @graphs = ();

# HTML interface vars.
my $html;
my $html_prgm_name;
my $html_graph_selector;
my $html_js;

sub Init {
	system('rm -fr img');
	system('rm -fr dot');
	mkdir 'img';
	mkdir 'dot';
}

sub AppendHeader {
	return '<!DOCTYPE HTML>
		<html>
		<head>
			<title>CS410 Thread Visualizer</title>
			<link href="bootstrap.css" rel="stylesheet">
			<link href="style.css" rel="stylesheet">
		</head>
		<body>
			<div class="container shadow">';
}

sub AppendProgramName {
	return "<div id=\"header\" class=\"row btm-border\">
			<h4>$html_prgm_name</h4>
		</div>";
}

sub AppendView {
	return "<div class=\"row\">		
		<!-- Image Section -->
		<div id=\"view\" class=\"col-md-8\">
			<img src=\"\" alt=\"\">
			<h4 id='title'></h4>
		</div>";
}

sub AppendButtonNav {
	return '<div id="control" class="col-md-4">
		<div id="btn-nav" class="row btm-border">
			<div class="btn-grp">
				<div class="btn" onclick="Timer(\'stop\'); StepFrame(\'back\');"><img src="step-backward.svg" alt=""/></div>
				<div id="stop" class="btn active" onclick="Timer(\'stop\');"><img src="stop.svg" alt=""/></div>
				<div id="play" class="btn" onclick="Timer(\'start\');"><img src="play.svg" alt=""/></div>
				<div class="btn" onclick="Timer(\'stop\'); StepFrame(\'next\');"><img src="step-forward.svg" alt=""/></div>
			</div>
			<!--table style="margin:0.5em;">
				<tr><td>Step Speed(ms)</td><td><input type="text" onkeypress="TimerDelay(this);" value="1600"/></td></tr>
			</table-->
		</div>';
}

sub AppendGraphSelectorHeader {
	return '<!-- View Section -->
			<div id="frame-select" class="row btm-border">
				<ul id="frame-select-list">';
}

sub AppendGraphSelector {
	return $html_graph_selector;
}

sub AppendGraphSelectorFooter {
	return '</ul>
		</div>';
}

sub AppendGraphDetails {
	return '<div id="details" class="row">
								<table>
								</table>
							</div>
						</div>

			</div>
		</div>';
}

sub AppendScripts {
	return "<script src=\"main.js\"></script>
			<script>
				var abc;
				$html_js
				abc = document.getElementById('frame-select-list').firstChild.firstChild;
				ChangeView(document.getElementById('frame-select-list').firstChild.firstChild);
			</script>
			</body>
		</html>"; 
}

sub BuildInterface {
	my $html = AppendHeader;
	$html .= AppendProgramName('Program Name');
	$html .= AppendView;
	$html .= AppendButtonNav;
	$html .= AppendGraphSelectorHeader;
	$html .= AppendGraphSelector;
	$html .= AppendGraphSelectorFooter;
	$html .= AppendGraphDetails;
	$html .= AppendScripts;
	open (INTERFACE, ">", "html/index.html");
	print INTERFACE $html;
	close (INTERFACE);
}

sub PNGFileName {
	my $num = sprintf("%03d", $_[0]);
	return "output$num.png";
}

sub SVGFileName {
	my $num = sprintf("%03d", $_[0]);
	return "output$num.svg";
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

sub WriteHTMLSelector {
	if ($_[2]) {
		$html_graph_selector .= "<li class=\"active\"><a href=\"#$_[1]\" onclick=\"Timer('stop'); ChangeView(this);\">$_[0]</a></li>\n";
	}
	else {
		$html_graph_selector .= "<li><a href=\"#$_[1]\" onclick=\"Timer('stop'); ChangeView(this);\">$_[0]</a></li>\n";
	}
}

sub WriteHTMLDetails {
	foreach my $key (keys %objects) {
		$html_js .= "LoadStateView($_[1],\"$_[0]\");\n";
		$html_js .= "LoadState($_[1] -1,\"$key\",\"$objects{$key}{'Type'}\",\"$objects{$key}{'Status'}\",\"$objects{$key}{'Label'}\",\"$callingThread\",\"$enterExit\",\"$functionName\",\"$argumentList\");";
	}
}

sub WriteDOTFile {
	#Prints out to our DOT file progressively each line.
	my $num = sprintf("%03d", $_[0]);
	my $dotFilename = "graph".$num.".dot";
	open (GRAPHFILE, ">", "dot/".$dotFilename);
	print GRAPHFILE "digraph G {\n";
	print GRAPHFILE "graph[center=true, ratio=1];\n";
	foreach my $key (keys %objects) {
		if ($objects{$key}{'Type'} eq "Thread") {
			my $startRoutine = $key .'\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Alive") {
				print GRAPHFILE "$key [color=black,label=\"$startRoutine\"];\n";
			}
			if ($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [color=lightgrey,label=\"$startRoutine\"];\n";
			}
			# print links to children
			my @children = split ',', $objects{$key}{'Children'};
			foreach my $child (@children) {
				if ($objects{$child}{'Status'} ne "Dead") {
					print GRAPHFILE "$key -> $child [style=dotted,arrowhead=normal,penwidth=3];\n";
				}
				else {
					print GRAPHFILE "$key -> $child [style=dotted,arrowhead=normal,color=grey,penwidth=3];\n";
				}
			}
			# deals with printing out all edges for threads
			foreach my $linkKey (keys %{$objects{$key}{'Links'}}) {
				if ($objects{$key}{'Links'}{$linkKey} eq "join") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=odot,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "joined") {
					print GRAPHFILE "$linkKey -> $key" . " [arrowhead=odot,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "failedjoin") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=odot,color=grey,penwidth=3];\n";
				}
				if ($objects{$key}{'Links'}{$linkKey} eq "cancel") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=normal,color=yellow,penwidth=3];\n";
				}
				if ($objects{$key}{'Links'}{$linkKey} eq "cancelled") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=normal,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "lock") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "locked") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=green,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "failedlock") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=normal,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "unlock") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=green,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "unlocked") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq 'cond-unlocked') {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=grey,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "blocked") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "returned") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=normal,color=grey,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "timedoutwait") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=normal,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "signal") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,color=green,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endsignal") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "broadcast") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,color=green,penwidth=6];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endbroadcast") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,color=grey,penwdith=6];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "rdlock") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=dot,color=blue,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "wrlock") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=dot,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "rwunlocked") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=dot,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "spinlock") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=diamond,color=black,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "spinunlocked") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=diamond,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "barrier") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=box,color=black,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "maxed barrier") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=box,color=grey,penwidth=3];\n";
				}
			}
		}
		elsif ($objects{$key}{'Type'} eq "Mutex") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=trapezium,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=trapezium,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=trapezium,color=lightgrey,label=\"$variableName\"]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Condition Variable") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unblocked") {
				print GRAPHFILE "$key [shape=parallelogram,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Blocked") {
				print GRAPHFILE "$key [shape=parallelogram,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=parallelogram,color=lightgrey,label=\"$variableName\"]\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "RWLock") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=invtriangle,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=invtriangle,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=invtriangle,color=lightgrey,label=\"$variableName\"];\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Spinlock") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=box,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=box,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=box,color=lightgrey,label=\"$variableName\"];\n";
			}
		}
		elsif ($objects{$key}{'Type'} eq "Barrier") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unused") {
				print GRAPHFILE "$key [shape=octagon,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Used") {
				print GRAPHFILE "$key [shape=octagon,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=octagon,color=lightgrey,label=\"$variableName\"];\n";
			}
		}
	}
	print GRAPHFILE "}";
	close (GRAPHFILE);
	return $dotFilename;
}

sub DrawPNG {
	# Pad number with leading zeros.
	my $num = sprintf("%03d", $_[1]);
	my $cmd = 'dot -Tpng dot/'. $_[0] .' > img/output' . $num . '.png';
	system($cmd);
}

sub DrawSVG{
	# Pad number with leading zeros.
	my $num = sprintf("%03d", $_[1]);
	my $cmd = 'dot -Tsvg dot/'. $_[0] .' > img/output' . $num . '.svg';
	system($cmd);
}

sub CreateGIF {
	system('convert -delay 100 -loop 0 img/output*.png img/view.gif');
}

&Init();
# All variable names currently temporary.
open (TIMESTAMPS, ">", "timestamps.txt");

#open (LOGFILE, "logfile.txt") or die "Could not find specified logfile.";
open (LOGFILE, "../libthreadtrace/libthreadtrace.log") or die "Could not find specified logfile.";

$html_prgm_name = <LOGFILE>;
$count = 1;
while (<LOGFILE>) {
	# Read a max of 100 lines
	if ($count == 300) {
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

	# Scenarios for different functions. Assuming that all pthread calls will pass, besides the ones which wait
	if($functionName eq "pthread_create" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		my %links;
		$objects{$arguments[0]} = {
			'Type' => 'Thread',
			'Label' => $arguments[2],
			'Status' => 'Alive',
			'Children' => '',
			'Links' => %links};
		if (exists $objects{$callingThread}) {
			$objects{$callingThread}{'Children'} = $objects{$callingThread}{'Children'} . "$arguments[0],";
		}
		else {
			$objects{$callingThread} = {'Type' => 'Thread',
						    'Label' => '{root}',
						    'Status' => 'Alive',
						    'Children' => "$arguments[0],",
						    'Links' => %links};
		}
	}
	elsif (($functionName eq "pthread_join" || $functionName eq "pthread_tryjoin" || $functionName eq "pthread_timedjoin") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'join';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_join" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'joined';
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_tryjoin" || $functionName eq "pthread_timedjoin") && $enterExit eq "EXIT") {
		if ($stackOrReturn ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedjoin';
		}
		else {
			if (exists $objects{$arguments[0]}) {
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'joined';
			}
			else {
				next;
			}
		}
	}
	elsif($functionName eq "pthread_cancel" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'cancel';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cancel" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'cancelled';
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_exit" && $enterExit eq "ENTER") {
		if (exists $objects{$callingThread}) {
			$objects{$callingThread}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_mutex_init" && $enterExit eq "ENTER") {
		my %links;
		$objects{$arguments[0]} = {'Type' => 'Mutex',
					   'Label' => $arguments[1],
					   'Status' => 'Unlocked',
					   'Locked by' => ''};
		if (exists $objects{$callingThread}) {
			$objects{$callingThread}{'Children'} = $objects{$callingThread}{'Children'} . "$arguments[0],";
		}
		else {
			$objects{$callingThread} = {'Type' => 'Thread',
						    'Label' => '{root}',
						    'Status' => 'Alive',
						    'Children' => "$arguments[0],",
						    'Links' => %links};
		}
	}
	elsif(($functionName eq "pthread_mutex_lock" || $functionName eq "pthread_mutex_trylock" || $functionName eq "pthread_mutex_timedlock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			if ($objects{$arguments[0]}{'Locked by'} ne $callingThread) {
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'lock';
			}
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_mutex_lock" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'locked';
			$objects{$arguments[0]}{'Locked by'} = $callingThread;
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_mutex_trylock" || $functionName eq "pthread_mutex_timedlock") && $enterExit eq "EXIT") {
		if ($stackOrReturn ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedlock';
		}
		else {
			if (exists $objects{$arguments[0]}) {
        	                $objects{$arguments[0]}{'Status'} = 'Locked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'locked';
				$objects{$arguments[0]}{'Locked by'} = $callingThread;
        	        }
			else {
				next;
			}
		}
	}
	elsif($functionName eq "pthread_mutex_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'unlock';
		}
		else {
			next;
		}
	}	
	elsif($functionName eq "pthread_mutex_unlock" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'unlocked';
			$objects{$arguments[0]}{'Locked by'} = '';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_mutex_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_init" && $enterExit eq "ENTER") {
		my %links;
		$objects{$arguments[0]} = {'Type' => 'Condition Variable',
					   'Label' => $arguments[1],
					   'Status' => 'Unblocked'};
		if (exists $objects{$callingThread}) {
			$objects{$callingThread}{'Children'} = $objects{$callingThread}{'Children'} . "$arguments[0],";
		}
		else {
			$objects{$callingThread} = {'Type' => 'Thread',
						    'Label' => '{root}',
						    'Status' => 'Alive',
						    'Children' => "$arguments[0],",
						    'Links' => %links};
		}
	}
	elsif(($functionName eq "pthread_cond_wait" || $functionName eq "pthread_cond_timedwait") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Blocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'blocked';
			$objects{$arguments[1]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[1]} = 'cond-unlocked';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_wait" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unblocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'returned';
			$objects{$arguments[1]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[1]} = 'locked';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_timedwait" && $enterExit eq "EXIT") {
		if ($stackOrReturn ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'timedoutwait';
		}
		else {
			if (exists $objects{$arguments[0]}) {
				$objects{$arguments[0]}{'Status'} = 'Unblocked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'returned';
				$objects{$arguments[1]}{'Status'} = 'Locked';
				$objects{$callingThread}{'Links'}{$arguments[1]} = 'locked';
			}
			else {
				next;
			}
		}
	}
	elsif($functionName eq "pthread_cond_signal" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'signal';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_signal" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endsignal';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_broadcast" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'broadcast';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_broadcast" && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endbroadcast';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_barrier_init" && $enterExit eq "ENTER") {
		my @threads;
		$objects{$arguments[0]} = {'Type' => 'Barrier',
					   'Label' => $arguments[1],
					   'Status' => 'Unused',
					   'Count' => 0,
					   'Max' => $arguments[3],
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
					$objects{$thread}{'Links'}{$arguments[0]} = 'maxed barrier';
				}
				$objects{$arguments[0]}{'Threads Waiting'} = @empty;	 
			}
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_barrier_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_init" && $enterExit eq "ENTER") {
		$objects{$arguments[0]} = {'Type' => 'Spinlock',
					   'Label' => $arguments[1],
					   'Status' => 'Unlocked'};
	}
	elsif($functionName eq "pthread_spin_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_spin_lock" || $functionName eq "pthread_spin_trylock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'spinlock';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'spinunlocked';
		}
		else {
			next;
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
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_wrlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'wrlock';
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_rwlock_trywrlock" || $functionName eq "pthread_rwlock_timedrdlock") && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'wrlock';
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_rwlock_tryrdlock" || $functionName eq "pthread_rwlock_timedwrlock") && $enterExit eq "EXIT" && $stackOrReturn eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rdlock';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rwunlocked';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_destroy" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	else {
		next;
	}

	my $filename = &WriteDOTFile($count);
	&DrawSVG($filename, $count);

	if (1 == $count) {
		&WriteHTMLSelector(&SVGFileName($count),$count,1);
	}
	else {
		&WriteHTMLSelector(&SVGFileName($count),$count,0);
	}

	&WriteHTMLDetails(&SVGFileName($count),$count);
	
	$count++;	
}

# Dump objects.
open (OBJECTS, ">", "objects.txt");
print OBJECTS Dumper(%objects);
close(OBJECTS);

#&DrawLegend();
close (TIMESTAMPS);
close (LOGFILE);

#&CreateGIF();
&BuildInterface();
exit;
