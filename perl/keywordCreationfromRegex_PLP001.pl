#! /usr/bin/perl -w

# CUSTOM SCRIPT FOR PLP001 TO READING A FILE CONTAINING KEYWORDS AND CREATE A FILES TO BE MIGRATED CSV FILE

use strict;
use warnings;
use Tie::File;
use Fcntl;

my $filename = 'PLPFileScanAugustLatest.txt';
my $changed_line = 0;
my $index;
my $quotes;
my $keyword = 0;
my (@records, $record);
my $value;
my $counter = 1;

#Tie Files_To_Be_Migrated.csv to array object and allow for 500MB of cache memory, open in read/write mode
tie(@records, 'Tie::File', "Files_To_Be_Migrated.csv", mode => O_RDWR, memory => 500_000_000) or die "Can't tie to Files_To_Be_Migrated.csv : $|\n";

#File handle calls
open(my $filehandle, $filename) or die "Could not file '$filename' ";

#Iterate through file list
 while(my $original_line = <$filehandle>){
	chomp $original_line;

	#Search for the regex in every line. If present save to variable
	if($original_line =~ /(\d{3}\s\d{4}x?)/){
		$changed_line = $1;
		$index = substr($changed_line, 4, 1);
	}else{
		$index = 0;
	}

	#Match 5th character to keywords following file naming scheme of client
	for($index){
		if		(/1/) 		{ $keyword = "\"Drawings\;Sketches\;Plans\;Diagrams\"" }
		elsif	(/2/) 		{ $keyword = "\"Models\"" }
		elsif	(/3/) 		{ $keyword = "\"Renderings\"" }
		elsif	(/4/) 		{ $keyword = "\"Construction\"" }
		elsif	(/5/) 		{ $keyword = "\"Building Exterior\"" }
		elsif	(/6/) 		{ $keyword = "\"Building Interior\"" }
		elsif	(/7/) 		{ $keyword = "\"Reference\"" }
		elsif	(/[^1-7]/) 	{ $keyword = "\"Does Not Conform to Naming Rule\"" }
	}

	#Find if x is present in file name to determine preferred image for Rank 1 in OA
	$index = index($changed_line, 'x');
	if($index >= 0){
		$keyword = $keyword . "\;Rank1";
	}

	#Switch slashes
	$original_line =~ s/\\/\//g;

	#Defer writing of file till the end to avoid constant disk access
	(tied @records)->defer;

	#Match line of filescan.txt to line in Files_To_Be_Migrated.csv and append keyword string if necessary
	foreach $record (@records){
		$value = index($record, $original_line);
		if($value >= 0) {
			$quotes = substr($record, -1);
			#Check if last character is a ". If exists delete
			if($quotes eq "\"") {
				chop($record);
				#Change beginning " to ; to be able to append to existing keywords in Data Migration column
				$keyword =~ s+^\"+\;+;
				$record = $record . $keyword;
			} else {
				$record = $record . $keyword;
			}
			print "$record\n";
			last;
		}
	}

	(tied @records)->flush;

	print "***$counter***\n";
	$keyword = "";
	$counter++;

 }

 untie @records;
 close $filehandle;
