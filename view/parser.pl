#!/usr/bin/perl -w
# scripting flags
use strict;
use warnings;
use Data::Dumper;

# Config
my $maxFrames = 1024;
#my $logfile = "/tmp/libthreadtrace.log";
my $logfile = "libthreadtrace.log";

# Globals
my $timestamp;
my $callingThread;
my $enterExit;
my $functionName;
my $argumentList;
my $return;
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

# Methods for generating intermediate image files
sub DrawPNG {
	my $num = sprintf("%03d", $_[1]);
	my $cmd = 'dot -Tpng dot/'. $_[0] .' > img/output' . $num . '.png';
	system($cmd);
}
sub DrawSVG{
	my $num = sprintf("%03d", $_[1]);
	my $cmd = 'dot -Tsvg dot/'. $_[0] .' > img/output' . $num . '.svg';
	system($cmd);
}
# Methods for referencing intermediate image files
sub PNGFileName {
	my $num = sprintf("%03d", $_[0]);
	return "output$num.png";
}
sub SVGFileName {
	my $num = sprintf("%03d", $_[0]);
	return "output$num.svg";
}

# Generate .gif from .png files
sub CreateGIF {
	system('convert -delay 100 -loop 0 img/output*.png img/view.gif');
}

# Functions for generating html/index.html for .svg files
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


# Function to print out a DOT file based on our current thread, lock, condition variable and barrier state. Called after the processing of every log entry resulting in a change to the mentioned state.
sub WriteDOTFile {
	my $num = sprintf("%03d", $_[0]);
	my $dotFilename = "graph".$num.".dot";
	open (GRAPHFILE, ">", "dot/".$dotFilename);
	print GRAPHFILE "digraph G {\n";
	print GRAPHFILE "graph[center=true, ratio=1];\n";

	# loop through $objects map
	foreach my $key (keys %objects) {
		# if object being processed is a thread
		if ($objects{$key}{'Type'} eq "Thread") {
			my $label = $key .'\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Alive") {
				print GRAPHFILE "$key [color=black,label=\"$label\"];\n";
			}
			if ($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [color=lightgrey,label=\"$label\"];\n";
			}
			# print out edges between child and parent threads
			my @children = split ',', $objects{$key}{'Children'};
			foreach my $child (@children) {
				if ($objects{$child}{'Status'} ne "Dead") {
					print GRAPHFILE "$key -> $child [style=dotted,arrowhead=normal,penwidth=3];\n";
				}
				else {
					print GRAPHFILE "$key -> $child [style=dotted,arrowhead=normal,color=grey,penwidth=3];\n";
				}
			}
			# print out all other links between threads and objects
			foreach my $linkKey (keys %{$objects{$key}{'Links'}}) {
				if ($objects{$key}{'Links'}{$linkKey} eq "join") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=odot,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endjoin") {
					print GRAPHFILE "$linkKey -> $key" . " [arrowhead=odot,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "failedjoin") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=odot,color=grey,penwidth=3];\n";
				}
				if ($objects{$key}{'Links'}{$linkKey} eq "cancel") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=daimond,color=yellow,penwidth=3];\n";
				}
				if ($objects{$key}{'Links'}{$linkKey} eq "endcancel") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=daimond,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "lock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "rdlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=blue,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "wrlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "spinlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=green,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endrdlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=blue,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endwrlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=green,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endspinlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=yellow,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "failedlock") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "unlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=green,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endunlock") {
					print GRAPHFILE "$key -> $linkKey" . " [color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq 'cond-endunlock') {
					print GRAPHFILE "$key -> $linkKey" . " [color=grey,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "condwait") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=dot,color=red,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endcondwait") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=dot,color=grey,dir=back,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "timedout") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=dot,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "signal") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=dot,color=green,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endsignal") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=dot,color=grey,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "broadcast") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=dot,color=green,penwidth=6];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endbroadcast") {
					print GRAPHFILE "$key -> $linkKey" . " [style=dashed,arrowhead=dot,color=grey,penwdith=6];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "barrierwait") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=box,color=yellow,penwidth=3];\n";
				}
				elsif ($objects{$key}{'Links'}{$linkKey} eq "endbarrierwait") {
					print GRAPHFILE "$key -> $linkKey" . " [arrowhead=box,color=grey,penwidth=3];\n";
				}
			}
		}
		# mutex case
		elsif ($objects{$key}{'Type'} eq "Mutex") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=trapezium,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=trapezium,color=red,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=trapezium,color=lightgrey,label=\"$variableName\"]\n";
			}
		}
		# cond case
		elsif ($objects{$key}{'Type'} eq "Condition Variable") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unblocked") {
				print GRAPHFILE "$key [shape=parallelogram,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Blocked") {
				print GRAPHFILE "$key [shape=parallelogram,color=red,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=parallelogram,color=lightgrey,label=\"$variableName\"]\n";
			}
		}
		# rwlock case
		elsif ($objects{$key}{'Type'} eq "RWLock") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=trapezium,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "RDLocked") {
				print GRAPHFILE "$key [shape=trapezium,color=blue,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "WRLocked") {
				print GRAPHFILE "$key [shape=trapezium,color=red,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=trapezium,color=lightgrey,label=\"$variableName\"];\n";
			}
		}
		# spin case
		elsif ($objects{$key}{'Type'} eq "Spinlock") {
			my $variableName = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Unlocked") {
				print GRAPHFILE "$key [shape=trapezium,color=black,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Locked") {
				print GRAPHFILE "$key [shape=trapezium,color=yellow,label=\"$variableName\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=trapezium,color=lightgrey,label=\"$variableName\"];\n";
			}
		}
		# barrier case
		elsif ($objects{$key}{'Type'} eq "Barrier") {
			my $label = $key . '\n' . $objects{$key}{'Label'};
			if ($objects{$key}{'Status'} eq "Done") {
				print GRAPHFILE "$key [shape=box,color=black,label=\"$label\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Waiting") {
				$label = $label . '\n' . 'Remaining: ' . ($objects{$key}{'Max'} - $objects{$key}{'Count'});
				print GRAPHFILE "$key [shape=box,color=yellow,label=\"$label\"];\n";
			}
			elsif($objects{$key}{'Status'} eq "Dead") {
				print GRAPHFILE "$key [shape=box,color=lightgrey,label=\"$label\"];\n";
			}
		}
	}

	# finish output file
	print GRAPHFILE "}";
	close (GRAPHFILE);
	return $dotFilename;
}


&Init();
open (TIMESTAMPS, ">", "timestamps.txt");
open (LOGFILE, $logfile) or die "Could not find specified logfile.";

$html_prgm_name = <LOGFILE>;
$count = 1;
while (<LOGFILE>) {
	if ($count == $maxFrames) {
		last;
	}
	chomp;
	# Splitting information in logfile by tab spaces
	($timestamp, $callingThread, $enterExit, $functionName, $argumentList, $return) = split(' ');
	# Chop off first and last characters
	$argumentList = substr substr($argumentList, 1), 0, -1;
	# Remove white spaces
	$argumentList =~ s/\s+//g;
	@arguments = split ',', $argumentList;
	# Logging the timestamps assuming that every line is a new thread state
	print TIMESTAMPS "Thread $callingThread Timestamp: $timestamp";

	# Scenarios for different functions. Assuming that all pthread calls will pass, besides the ones which wait
	if($functionName eq "pthread_create" && $enterExit eq "EXIT" && $return eq "0") {
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
	elsif($functionName eq "pthread_join" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endjoin';
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_tryjoin" || $functionName eq "pthread_timedjoin") && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedjoin';
		}
		else {
			if (exists $objects{$arguments[0]}) {
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endjoin';
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
	elsif($functionName eq "pthread_cancel" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endcancel';
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
	elsif($functionName eq "pthread_mutex_init" && $enterExit eq "EXIT") {
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
	elsif($functionName eq "pthread_mutex_lock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endlock';
			$objects{$arguments[0]}{'Locked by'} = $callingThread;
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_mutex_trylock" || $functionName eq "pthread_mutex_timedlock") && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedlock';
		}
		else {
			if (exists $objects{$arguments[0]}) {
        	                $objects{$arguments[0]}{'Status'} = 'Locked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endlock';
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
	elsif($functionName eq "pthread_mutex_unlock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endunlock';
			$objects{$arguments[0]}{'Locked by'} = '';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_mutex_destroy" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_init" && $enterExit eq "EXIT") {
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
						    'Count' => 0};
		}
	}
	elsif(($functionName eq "pthread_cond_wait" || $functionName eq "pthread_cond_timedwait") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Blocked';
			$objects{$arguments[0]}{'Count'}++;
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'condwait';
			$objects{$arguments[1]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[1]} = 'cond-endunlock';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_wait" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Count'}--;
			if ($objects{$arguments[0]}{'Count'} == 0) {
				$objects{$arguments[0]}{'Status'} = 'Unblocked';
			}
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endcondwait';
			$objects{$arguments[1]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[1]} = 'endlock';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_timedwait" && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'timedout';
			$objects{$arguments[0]}{'Count'}--;
		}
		else {
			if (exists $objects{$arguments[0]}) {
				$objects{$arguments[0]}{'Count'}--;
				if ($objects{$arguments[0]}{'Count'} == 0) {
					$objects{$arguments[0]}{'Status'} = 'Unblocked';
				}
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endcondwait';
				$objects{$arguments[1]}{'Status'} = 'Locked';
				$objects{$callingThread}{'Links'}{$arguments[1]} = 'endlock';
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
	elsif($functionName eq "pthread_cond_signal" && $enterExit eq "EXIT" && $return eq "0") {
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
	elsif($functionName eq "pthread_cond_broadcast" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endbroadcast';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_cond_destroy" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_init" && $enterExit eq "EXIT") {
		my %readers;
		$objects{$arguments[0]} = {'Type' => 'RWLock',
					   'Label' => $arguments[1],
					   'Status' => 'Unlocked',
					   'ReaderCount' => 0,
					   'Readers' => %readers};
	}
	elsif(($functionName eq "pthread_rwlock_rdlock" || $functionName eq "pthread_rwlock_tryrdlock" || $functionName eq "pthread_rwlock_timedrdlock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			if (exists ($objects{$arguments[0]}{'Readers'}{$callingThread}) {
				next;	
			}
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'rdlock';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_rdlock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			if (exists ($objects{$arguments[0]}{'Readers'}{$callingThread}) {
				next;	
			}
			$objects{$arguments[0]}{'Status'} = 'RDLocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endrdlock';
			$objects{arguments[0]}{'ReaderCount'}++;
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_rwlock_tryrdlock" || $functionName eq "pthread_rwlock_timedrdlock") && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedlock';
		}
		else {
			if (exists $objects{$arguments[0]}) {
				if (exists ($objects{$arguments[0]}{'Readers'}{$callingThread}) {
					next;	
				}
        	                $objects{$arguments[0]}{'Status'} = 'RDLocked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endrdlock';
				$objects{arguments[0]}{'ReaderCount'}++;
        	        }
			else {
				next;
			}
		}
	}
	elsif(($functionName eq "pthread_rwlock_wrlock" || $functionName eq "pthread_rwlock_trywrlock" || $functionName eq "pthread_rwlock_timedwrlock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			if ($objects{$arguments[0]}{'Locked by'} ne $callingThread) {
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'wrlock';
			}
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_wrlock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'WRLocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endwrlock';
			$objects{$arguments[0]}{'Locked by'} = $callingThread;
		}
		else {
			next;
		}
	}
	elsif(($functionName eq "pthread_rwlock_trywrlock" || $functionName eq "pthread_rwlock_timedwrlock") && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedlock';
		}
		else {
			if (exists $objects{$arguments[0]}) {
        	                $objects{$arguments[0]}{'Status'} = 'WRLocked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endwrlock';
				$objects{$arguments[0]}{'Locked by'} = $callingThread;
        	        }
			else {
				next;
			}
		}
	}
	elsif($functionName eq "pthread_rwlock_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'unlock';
		}
		else {
			next;
		}
	}	
	elsif($functionName eq "pthread_rwlock_unlock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			if (exists $objects{arguments[0]}{'Readers'}{$callingThread}) {
				$objects{arguments[0]}{'ReaderCount'}--;
				delete $objects{arguments[0]}{'Readers'}{$callingThread};
				if ($objects{arguments[0]}{'ReaderCount'} == 0) {
					$objects{$arguments[0]}{'Status'} = 'Unlocked';
				}
			}
			else {
				$objects{$arguments[0]}{'Status'} = 'Unlocked';
			}
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endunlock';
			$objects{$arguments[0]}{'Locked by'} = '';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_rwlock_destroy" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_init" && $enterExit eq "EXIT") {
		$objects{$arguments[0]} = {'Type' => 'Spinlock',
					   'Label' => $arguments[1],
					   'Status' => 'Unlocked'};
	}
	elsif(($functionName eq "pthread_spin_lock" || $functionName eq "pthread_spin_trylock") && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			if ($objects{$arguments[0]}{'Locked by'} ne $callingThread) {
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'spinlock';
			}
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_lock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Locked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endspinlock';
			$objects{$arguments[0]}{'Locked by'} = $callingThread;
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_trylock" && $enterExit eq "EXIT") {
		if ($return ne "0") {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'failedlock';
		}
		else {
			if (exists $objects{$arguments[0]}) {
        	                $objects{$arguments[0]}{'Status'} = 'Locked';
				$objects{$callingThread}{'Links'}{$arguments[0]} = 'endspinlock';
				$objects{$arguments[0]}{'Locked by'} = $callingThread;
        	        }
			else {
				next;
			}
		}
	}
	elsif($functionName eq "pthread_spin_unlock" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'unlock';
		}
		else {
			next;
		}
	}	
	elsif($functionName eq "pthread_spin_unlock" && $enterExit eq "EXIT" && $return eq "0") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Unlocked';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endunlock';
			$objects{$arguments[0]}{'Locked by'} = '';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_spin_destroy" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Dead';
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_barrier_init" && $enterExit eq "EXIT") {
		$objects{$arguments[0]} = {'Type' => 'Barrier',
					   'Label' => $arguments[1],
					   'Status' => 'Done',
					   'Max' => $arguments[3],
					   'Count' => 0};
	}
	elsif($functionName eq "pthread_barrier_wait" && $enterExit eq "ENTER") {
		if (exists $objects{$arguments[0]}) {
			$objects{$arguments[0]}{'Status'} = 'Waiting';
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'barrierwait';
			$objects{$arguments[0]}{'Count'}++;
		}
	}
	elsif($functionName eq "pthread_barrier_wait" && $return eq "0" && $enterExit eq "EXIT") {
		if (exists $objects{$arguments[0]}) {
			$objects{$callingThread}{'Links'}{$arguments[0]} = 'endbarrierwait';
			$objects{$arguments[0]}{'Count'}--;
			if ($objects{$arguments[0]}{'Count'} == 0) {
				$objects{$arguments[0]}{'Status'} = 'Done';
			}
		}
		else {
			next;
		}
	}
	elsif($functionName eq "pthread_barrier_destroy" && $enterExit eq "EXIT") {
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

	# If loop has reached this point, $LINE caused a change in the thread/lock/condition variable/barrier state.
	# Now generate the intermediate output files.
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
