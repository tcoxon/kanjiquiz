#!/usr/bin/perl

use strict;
use warnings;
use utf8;

sub split_readings {
    my $reading = shift;
    $reading =~ s/\s*,\s*|\s+or\s+|\s*;\s*/|/g;
    $reading
}

sub get_char {
    my $link = shift;
    $link =~ /^\s*\{\{lang\|ja\|\[\[wiktionary:(.+)\|(.+)\]\]\}\}\s*$/
        or die "Couldn't match link";
    $1 eq $2 or die "chars were different";
    $1;
}

if (scalar @ARGV != 2) {
    print "Usage: perl convert.pl <input-file> <output-file>\n";
    exit 1;
}

my ($input, $output) = @ARGV;

open INPUT, '<', $input or die "Couldn't open $input";
open OUTPUT, '>', $output or die "Couldn't open $output";

my $was_nl = 0;

for (<INPUT>) {
    chomp;
    if ($was_nl && /^\s*\|\s*(.+)$/) {
        my $content = $1;
        my @parts = split /\|\|/, $content;
        s/(^\s+|\s+$)//g for (@parts);
        my ($char, $meaning, $on_yomi, $kun_yomi) = @parts;
        $kun_yomi = "" if (!defined $kun_yomi);
        $meaning = split_readings($meaning);
        $on_yomi = split_readings($on_yomi);
        $kun_yomi = split_readings($kun_yomi);
        $char = get_char($char);
        print OUTPUT "$char,$meaning,$on_yomi,$kun_yomi\n";
    }

    $was_nl = /^\s*\|-\s*$/;
}

close INPUT;
close OUTPUT;
