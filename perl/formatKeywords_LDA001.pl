#! /usr/bin/perl -w

# CUSTOM SCRIPT FOR LDA001
# Read in the vales from LDA001_keywords.txt and format them in to the correct
# syntax for the files to be migrated sheet i.e. Energy;Renewables;Sustainability;Options;Development
# for each image ID

use strict;
use warnings;

my $filename = 'LDA001_keywords.txt';
my $outputfile = 'output.txt';
my $final_keyword = 5570; #value to remove in output
my $current_id = 26; #starting ID number

#File handle calls
open(my $filehandle, $filename) or die "Could not file '$filename' ";
#output file
open(my $fileoutput, '>>', $outputfile) or die "Could not file '$outputfile' ";

#Iterate through file list
 while(my $original_line = <$filehandle>){
	chomp $original_line;

    my $id = substr($original_line, 0, index($original_line, ','));
    my $keyword = substr($original_line, rindex($original_line, ',') + 1);

    if ($id == $current_id){
        $final_keyword = $final_keyword . $keyword . ';';
    } else {
        $final_keyword  = $current_id . ',' . $final_keyword;
        #write to file
        print $fileoutput "$final_keyword\n";

        $current_id = $id;
        $final_keyword = 5570;
        $final_keyword = $final_keyword . $keyword . ';';
    }
 }

 close $filehandle;
