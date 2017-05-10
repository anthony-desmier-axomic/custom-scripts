#!/usr/bin/perl -w
#
#
# Version 1.0
#
# Update keyword names in OpenAsset based on CSV file
#
#
# Basic way script works:
# 1) Run through the list of keyword IDs
# 2) Check if the keyword exists and if it does, then change the name to the corresponding value

# CSV File Setup: ** IMPORTANT **
#      Column 1 - Keyword ID
#      Column 2 - New keyword name

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;
use Getopt::Long;
use Pod::Usage;
use Text::CSV;
use FindBin;
use lib $FindBin::Bin.'/../Perl';
use OpenAsset::Setup;
use OpenAsset::Utils::LogUtils;
use File::Spec;

$|++;

my $setupFile;
my $imageIdList;
my $doUpdates;
my $updatedImages  = 0;
my $failedUpdates 	 = 0;
my $includeFirstLine = 0;
my $logLevel 	  	 = 'INFO';
my $errorLog         = 'failedUpdates.csv';
my $logFileHandle;

GetOptions( 's|setupFile=s'     		  =>\$setupFile,
            'k|keywordsToChange=s'        =>\$imageIdList,
			'i|includeFirstLine'          =>\$includeFirstLine,
            'u|doUpdates'                 =>\$doUpdates,
            'l|logLevel=s'      		  =>\$logLevel );

pod2usage(1) unless $setupFile&&$imageIdList;
OpenAsset::Utils::LogUtils->logToFileAndScreen($logLevel,'log.txt');
OpenAsset::Setup->initialize($setupFile) || exit;

require OpenAsset::Utils::BackupUtils;
require OpenAsset::M::Keyword;

my $log = Log::Log4perl->get_logger('');

&main();

sub main() {

	#&backupDatabase();
    &readInCSV();
	&displaySummary();

}

sub readInCSV() {
    my $csv = Text::CSV->new({'binary'=>1});
    $log->info('Reading in keyword list: '.$imageIdList);
    open(my $io, '< '.$imageIdList) or die 'Can\'t open '.$imageIdList;

    my $continue    = 1;

    while ($continue) {

        my $rowAR = $csv->getline($io);

        unless($includeFirstLine) {
            # skip first line
            $log->info('Skipping first line...');
			$includeFirstLine = 1;
            next;
        }
        if ($csv->eof()) {
            $continue = 0;
            last;
        } elsif (!$rowAR) {
            $log->warn('Problem parsing line: ');
            next;
        }

		my $imageId = &clean($rowAR->[0]);
		my $updatedOrigFilename = &clean($rowAR->[1]);
        my $image = new OpenAsset::M::Image($imageId);

		#Create file to log potential keyword retrieval failures

		open($logFileHandle, '> '.$errorLog);

        if($image){

            $log->info('Image Orignal Filename name is: ' .$image->originalFilename(). ' will change to : ' .$updatedOrigFilename);
            $image->original_filename($updatedOrigFilename);

            #actually update the keyword
            if($doUpdates){
                $log->info('...Actually changing original filename to: ' .$updatedOrigFilename);
                $image->__update();
                $updatedImages += 1;
            }

        } else {
            #The images was not found.
			$log->info('Image '.$imageId.' not found...');

			#write failed retrieval entry to error list spreadsheet
			print $logFileHandle 'Image '.$imageId.' not found...\n';

			$failedUpdates += 1;
        }


	}
	close($io);
	close($logFileHandle);

	#delete the error log if nothing failed
	if ($failedUpdates == 0){
		&removeErrorLog();
	}
}

sub removeErrorLog() {
	my $filePath = File::Spec->rel2abs( $errorLog ) ;
	unlink $filePath;
}

sub backupDatabase() {
	$log->info('Backing up database... ');
	  OpenAsset::Utils::BackupUtils->backupDatabase();
}

sub displaySummary() {
    $log->info('Images updated: '.$updatedImages);
    $log->info('Images not found: '.$failedUpdates);
	print "done\n";
}

sub clean($) {
    my $input = shift;
    $input =~ s|^\s||g;
    $input =~ s|\s$||g;
    return $input;
}


1;

__END__


=head1 SYNOPSIS

  CSV File Setup: ** IMPORTANT **

		Column 1 - Image ID
		Column 2 - New original filename

You must specify:

 -s --setupFile=SETUP_FILE                Path to setup file (e.g. OpenAsset_Setup_10_2_18.pl)
 -k --originalFilenamesToUpdate=CSV_FILE  Path to CSV file containing updated original filenames


Other options:

 -l --logLevel=LOG_LEVEL      DEBUG, INFO, WARN, ERROR or FATAL
 -i --includeFirstLine        Include the first line of CSV file
 -u --doUpdates               Actually update the keyword
