#!/usr/bin/perl
#
# Copyright (C) 2016 by Lieven Hollevoet

use strict;
use Test::More;
use lib './lib';
use lib '../lib';
use Data::Dumper;

use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($INFO);

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
is $data->{windSpeed}->{current}, 3, "Windspeed decoded";
is $data->{windDirection}->{current}, 248, "Wind direction decoded";

# Test packet that reports humidity
$data = $dut->decode("0 = A0\n\r1 = 02\n\r2 = 14\n\r3 = 90\n\r4 = 39\n\r5 = 09\n\r6 = E6\n\r7 = 6C\n\r8 = FF\n\r9 = FF\n\r\n\r");
print Dumper($data);
is $data->{'humidity'}->{'current'}, 91.2, "Humidity decoded as expected";

# Test a packet with failed CRC
# FA1EC51251E2374D7658
# 229869DC361F3C65737F
$data = $dut->decode("0 = 22\n\r1 = 98\n\r2 = 69\n\r3 = DC\n\r4 = 36\n\r5 = 1F\n\r6 = 3C\n\r7 = 65\n\r8 = 73\n\r9 = 7F\n\r\n\r");
print Dumper($data);
is $data->{'crc'}, 'fail', "CRC reported to be failed as expected";

done_testing();