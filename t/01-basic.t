#!/usr/bin/perl
#
# Copyright (C) 2016 by Lieven Hollevoet

use strict;
use Test::More;
use lib './lib';
use lib '../lib';

#use_ok 'IO::File';
use_ok 'Device::Davis::Strmon';

# Check default functions
can_ok ('Device::Davis::Strmon', qw(decode));

#my $stim = './t/stim/01-basic.txt';
#my $fh = IO::File->new( $stim, q{<} );

#isa_ok($fh, 'IO::File');

my $dut = Device::Davis::Strmon->new();

ok $dut, 'Object created';

# Test packet 70
my $data = $dut->decode("0 = 70\n\r1 = 2\n\r2 = B0\n\r3 = 0\n\r4 = 41\n\r5 = 89\n\r6 = CE\n\r7 = 92\n\r8 = FF\n\r9 = FF\n\r\n\r");
is $data->{windSpeed}, 3.218688, "Windspeed decoded";
is $data->{windDirection}, 247.8, "Wind direction decoded";

done_testing();