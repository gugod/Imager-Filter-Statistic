use strict;
use warnings;
package Imager::Filter::Statistic;

use Imager;
use Imager::Color;

sub summerize {
    my ($method, $pixels) = @_;
    $method = lc $method;
    my @c = map { [$_->rgba] } @$pixels;

    my @sum = (0,0,0);

    if ($method eq 'mean') {
        my @sum;
        for my $c (@c) {
            $sum[0] += $c->[0];
            $sum[1] += $c->[1];
            $sum[2] += $c->[2];
        }
        return [
            int($sum[0]/@c),
            int($sum[1]/@c),
            int($sum[2]/@c),
        ]
    } elsif ($method eq 'gradient') {
        my @max = (0,0,0);
        my @min = (255,255,255);
        for my $c (@c) {
            $min[0] = $c->[0] if $c->[0] < $min[0];
            $min[1] = $c->[1] if $c->[1] < $min[1];
            $min[2] = $c->[2] if $c->[2] < $min[2];
            $max[0] = $c->[0] if $c->[0] > $max[0];
            $max[1] = $c->[1] if $c->[1] > $max[1];
            $max[2] = $c->[2] if $c->[2] > $max[2];
        }
        return [
            $max[0] - $min[0],
            $max[1] - $min[1],
            $max[2] - $min[2],
        ]
    }
    die "unknown statistic method = $method";
}

sub statistic_filter {
    my %param = @_;

    my $img = $param{imager};
    my $img_copy = $img->copy();

    my ($w,$h) = split("x", $param{geometry});
    $h ||= $w;

    for my $y (0..$img->getheight-1) {
        for my $x (0..$img->getwidth-1) {
            my @px;
            for (0..$h) {
                push @px, $img_copy->getscanline(y=>$y+$_, x=>$x, width=>$w);
            }
            my $new_px = summerize($param{method}, \@px);
            
            $new_px = Imager::Color->new(@$new_px);
            my @new_px = map { $new_px } 0..$w-1;
            for (0..$h) {
                push @px, $img->setscanline(y=>$y+$_, x=>$x, pixels => \@new_px);
            }
        }
    }
}

Imager->register_filter(
    type     => 'statistic',
    callsub  => \&statistic_filter,
    callseq  => ['image', 'method', 'geometry'],
    defaults => {},
);

1;
