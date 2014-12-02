use strict;
use warnings;
package Imager::Filter::Statistic;

use List::Util qw<min max>;

use Imager;
use Imager::Color;

sub summerize {
    my ($ctx, $pixels) = @_;
    my $method = lc $ctx->{param}{method};
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
    } elsif ($method eq 'variance') {
        my @sum;
        for my $c (@c) {
            $sum[0] += $c->[0];
            $sum[1] += $c->[1];
            $sum[2] += $c->[2];
        }
        my @mean = (int($sum[0]/@c), int($sum[1]/@c), int($sum[2]/@c));
        my @variance = (0,0,0);
        for my $c (@c) {
            $variance[0] += ($c->[0] - $mean[0])**2 / $#c;
            $variance[1] += ($c->[1] - $mean[1])**2 / $#c;
            $variance[2] += ($c->[2] - $mean[2])**2 / $#c;
        }
        return \@variance;
    } elsif ($method eq 'min') {
        my @min = (255,255,255);
        for my $c (@c) {
            $min[0] = $c->[0] if $c->[0] < $min[0];
            $min[1] = $c->[1] if $c->[1] < $min[1];
            $min[2] = $c->[2] if $c->[2] < $min[2];
        }
        return \@min;
    } elsif ($method eq 'max') {
        my @max = (0,0,0);
        for my $c (@c) {
            $max[0] = $c->[0] if $c->[0] > $max[0];
            $max[1] = $c->[1] if $c->[1] > $max[1];
            $max[2] = $c->[2] if $c->[2] > $max[2];
        }
        return \@max;
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
    my $ctx = { param => \%param };

    my $img = $param{imager};
    my $img_copy = $img->copy();

    my ($w,$h) = split("x", $param{geometry});
    $w ||= $h;
    my $w_half_1 = int(($w-1)/2);
    my $w_half_2 = int($w/2);
    my $h_half_1 = int(($h-1)/2);
    my $h_half_2 = int($h/2);
    my $img_bound_x = $img->getwidth - 1;
    my $img_bound_y = $img->getheight - 1;

    for my $y (0 .. $img_bound_y) {
        for my $x (0..$img_bound_x) {
            my $y_0 = max(0, $y - $h_half_1);
            my $y_1 = min($y + $h_half_2, $img_bound_y);
            my $x_0 = max(0, $x - $w_half_1);
            my $x_1 = min($x + $w_half_2, $img_bound_x);
            my $w_ = $x_1 - $x_0 + 1;
            my @px = map { $img_copy->getscanline(y => $_, x => $x_0, width => $w_) } ($y_0 .. $y_1);
            my $new_px = summerize($ctx, \@px);
            $img->setpixel( y => $y, x => $x, color => $new_px);
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
