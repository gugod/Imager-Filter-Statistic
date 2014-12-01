use strict;
use warnings;
package Imager::Filter::Statistic;

use List::Util qw<min>;

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
    $h ||= $w;
    my $w_half = int($w/2) + 1;
    my $h_half = int($h/2) + 1;

    my $x_offset = $w_half - $w; # must be negative


    my $img_bound_x = $img->getwidth - 1;
    my $img_bound_y = $img->getheight - 1;
    
    for my $y (0 .. $img_bound_y) {
        for my $x (0..$img_bound_x) {
            my $x_l = ( $x < $w_half ) ? 0 : ($x + $x_offset);
            my $x_r = $x_l + $w;
            my $w_ = ($x_r > $img_bound_x) ? ($img_bound_x - $x_l) : $w;

            my @px;
            for my $y_ (($y+ $h_half-$w)..($y+ $h_half)) {
                next if $y_ < 0 || $y_ > $img_bound_y;
                push @px, $img_copy->getscanline(y => $y_, x => $x_l, width => $w_);
            }
            my $new_px = summerize($ctx, \@px);
            
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
