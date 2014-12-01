#!/usr/bin/env perl
use strict;
use warnings;
use Imager;
use Imager::Filter::Statistic;

my ($file, $output_dir) = @ARGV;

my $img = Imager->new(file => $file) or die Imager->errstr;

for my $method (qw< gradient variance min max mean >) {
    print "doing $method\n";
    my $img_copy = $img->copy;
    $img_copy->filter( type => "statistic", method => $method, "geometry" => "3x3" );
    $img_copy->write(file => "$output_dir/filter.$method.jpg");
    print "... done\n";
}




