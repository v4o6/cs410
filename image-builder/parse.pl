#!usr/bin/perl
# Parses log.data to generate an image file in the .dot format. output.dot can
# be fed to Graphviz to an generate an image.
#
use strict;
use warnings;

# Parse log file into @records.
open my $file, 'log.dat' or die "$!";
my @records = ();
while(my $line = <$file>) {   
	my @row = split /;/, $line;
	push @records, {
		timestamp => $row[0],
		id => $row[1],
		name => $row[2],
		parent => $row[3],
		location => $row[4]
	};
}
close $file;

# Sort @records by timestamp.
@records = sort {$a->{timestamp} <=> $b->{timestamp}} @records;

# Write @records to .dot format.
my $output = "digraph {\n";
foreach my $record (@records) {
	$output .= "\t" . $record->{parent} . " -> " . $record->{name} . ";\n";
}
$output .= "}\n";
open $file, '> input1.dot';
print $file $output;
close $file;

exit;