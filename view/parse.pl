#!usr/bin/perl
# Parses log.data to generate an image file in the .dot format. output.dot can
# be fed to Graphviz to an generate an image.
#
use strict;
use warnings;

# Parse log file into @events.
open my $file, 'log.dat' or die "$!";
my @events = ();
while(my $line = <$file>) {   
	my @row = split /;/, $line;
	push @events, {
		timestamp => $row[0],
		id => $row[1],
		name => $row[2],
		parent => $row[3],
		location => $row[4]
	};
}
close $file;

# Sort @events by timestamp.
@events = sort {$a->{timestamp} <=> $b->{timestamp}} @events;

# Write @events to .dot format.
my $output = "digraph {\n";
foreach my $event (@events) {
	$output .= "\t" . $event->{parent} . " -> " . $event->{name} . ";\n";
}
$output .= "}\n";
open $file, '> input.dot';
print $file $output;
close $file;

exit;