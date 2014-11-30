#!/usr/bin/env perl
use strict;
use warnings;
use Imager;
use Imager::Filter::Statistic;

my $file = shift @ARGV;
my $img = Imager->new(file => $file) or die Imager->errstr;
my $img_copy;

$img_copy = $img->copy;
$img_copy->filter( type => "statistic", method => "gradient", "geometry" => "3x3" );
$img_copy->write(file => "output.gradient.jpg");

# $img_copy = $img->copy;
# $img_copy->filter( type => "statistic", method => "mean", "geometry" => "3x3" );
# $img_copy->write(file => "output.mean.jpg");



