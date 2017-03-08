#! /usr/bin/perl -w

#
# THIS SCRIPT CAN BE USED TO EXTRACT THE EXISTING IMAGE ID AND DUPLICATE FILE PATH FROM THE CSV ERROR LOG FILE THAT IS PRODUCED BY THE LAN TO CLOUD MIGRATION SCRIPT
#
# THIS CAN BE USEFUL TO APPLY FILE KEYWORDS FROM DUPLICATE IMAGES TO IMAGES THAT ALREADY EXIST IN OPENASSET
#

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;
use Getopt::Long;
use Pod::Usage;
use Text::CSV;
use JSON;
use FindBin;
use lib $FindBin::Bin.'/../Perl';

$|++;

my $setupFile;
my $logLevel = 'INFO';
my $csvFile;
my $doInserts;

GetOptions(
    'f|csvFile=s'  =>\$csvFile,
    'i|doInserts'  =>\$doInserts
);

pod2usage(1) unless $csvFile;

my $keywordsByImageIdHR = {};
my $filePathByIdHR      = {};

main();

sub main {
    readInCSV() || exit 1;
    # printCSV() || exit 1;
}


sub readInCSV() {
    if (-r $csvFile) {
        open(my $io, '< '.$csvFile) or die 'Unable to open input CSV';

        my $continue    = 1;
        my $i           = 0;

        my $noKeywords      = 0;
        my $keywordsFound   = 0;

        my $csv = Text::CSV->new({'binary'=>1, 'eol'=>$/});

        while ($continue) {
            $i++;
            my $rowAR = $csv->getline($io);
            if ($csv->eof()) {
                $continue = 0;
                next;
            } elsif ($i==1) {
                next;
            }

            my $filePath    = $rowAR->[0];
            my $JSONString  = $rowAR->[1];

            my $jsonHR = {};
            eval {
                $jsonHR = JSON::from_json($JSONString);
            };
            if ($@) {
                next;
            }

            my $fileId = $jsonHR->{'existing_id'};

            if (!$fileId) {
                next;
            }

            print "$fileId,\"$filePath\"\n";

            # unless ($filePathByIdHR->{$fileId}) {
                # $filePathByIdHR->{$fileId} = [];
            # }
            # push(@{$filePathByIdHR->{$fileId}}, $filePath);


            # unless ($keywordsByImageIdHR->{$fileId}) {
                # $keywordsByImageIdHR->{$fileId} = {};
            # }

            # my @splitFilePath = split('/', $filePath);
            # pop(@splitFilePath);
            # foreach my $segment (@splitFilePath) {
                # if ($segment =~ /^(all|slideshow|pr)$/i) {
                    # $keywordsByImageIdHR->{$fileId}->{lc($1)} = 1;
                # }
            # }

        }

        # my $numbersHR = {};
        # foreach my $id (keys(%$keywordsByImageIdHR)) {
            # my $keywordHR = $keywordsByImageIdHR->{$id};
            # my $keywordAR = [ map { $_ } keys(%$keywordHR) ];

            # unless ($numbersHR->{scalar(@$keywordAR)}) {
                # $numbersHR->{scalar(@$keywordAR)} = 0;
            # }
            # $numbersHR->{scalar(@$keywordAR)}++;

            # if (scalar(@$keywordAR) == 6) {
                # my $refPathAR = $filePathByIdHR->{$id};
                # print Dumper $refPathAR;
            # }

        # }

        # print Dumper $numbersHR;
    }
}

sub printCSV() {

    if (open(OUTFILE, '> has_keywords.csv')
    && open(OUTFILE_NO_KEYWORDS, '> no_keywords.csv')) {
        my $csv = Text::CSV->new({'binary'=>1, 'eol'=>$/});

        foreach my $fileId (keys(%$keywordsByImageIdHR)) {
            my $keywordHR   = $keywordsByImageIdHR->{$fileId};
            my $keywordAR   = [ map { $_ } keys(%$keywordHR) ];
            my $filePath    = $filePathByIdHR->{$fileId}[0];

            if (scalar(@$keywordAR) > 0) {
                $csv->combine($fileId, $filePath, join(';', @$keywordAR));
                print OUTFILE $csv->string();
            } else {
                $csv->combine($fileId, $filePath);
                print OUTFILE_NO_KEYWORDS $csv->string();
            }
        }

    }
    close(OUTFILE);
    close(OUTFILE_NO_KEYWORDS);
}



1;

__END__


=head1 SYNOPSIS

You must specify:

 -f --csvFile=CSV_FILE       Path to CSV file, one filename per row

Other options:

 -i --doInserts              Do the INSERTs on the Image2Album table
