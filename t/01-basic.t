#!/usr/bin/perl
#
# Copyright (C) 2016 by Lieven Hollevoet

use strict;
use Test::More;
use lib './lib';
use lib '../lib';
use Data::Dumper;

use Log::Log4perl qw(:easy);

#Log::Log4perl->easy_init($DEBUG);

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
my $data = $dut->decode("0 = 70\n\r1 = 2\n\r2 = B0\n\r3 = 0\n\r4 = 41\n\r5 = 89\n\r6 = CE\n\r7 = 92\n\r8 = 00\n\r9 = 00\n\r\n\r");

is $data->{windSpeed}->{current}, 3, "Windspeed decoded";
is $data->{windDirection}->{current}, 248, "Wind direction decoded";

# Test packet that reports humidity
$data = $dut->decode("0 = A0\n\r1 = 03\n\r2 = E5\n\r3 = 18\n\r4 = 3B\n\r5 = 07\n\r6 = 74\n\r7 = 1F\n\r8 = FF\n\r9 = FF\n\r\n\r");

is $data->{'humidity'}->{'current'}, 79.2, "Humidity decoded as expected";

# Test a packet with failed CRC
# FA1EC51251E2374D7658
# 229869DC361F3C65737F
$data = $dut->decode("0 = 22\n\r1 = 98\n\r2 = 69\n\r3 = DC\n\r4 = 36\n\r5 = 1F\n\r6 = 3C\n\r7 = 65\n\r8 = 73\n\r9 = 7F\n\r\n\r");
is $data->{'crc'}, 'fail, expected 6C52', "CRC reported to be failed as expected";

# High temperature reading?
# 8000BC34720070DCFFFF
# 20005E7741801084FFFF
# 50005EFF710053FEFFFF
my $input = $dut->_create_data('800314291b0ecdb4ffff');
$data = $dut->decode($input);
is $data->{'crc'}, 'ok', "CRC ok";
DEBUG Dumper($data);


$data = $dut->decode("0 = 20\n\r1 = 00\n\r2 = 5E\n\r3 = 77\n\r4 = 41\n\r5 = 80\n\r6 = 10\n\r7 = 84\n\r8 = 00\n\r9 = 00\n\r\n\r");
is $data->{'crc'}, 'ok', "CRC ok";
DEBUG Dumper($data);

$data = $dut->decode("0 = 50\n\r1 = 00\n\r2 = 5E\n\r3 = FF\n\r4 = 71\n\r5 = 00\n\r6 = 53\n\r7 = FE\n\r8 = 00\n\r9 = 00\n\r\n\r");
is $data->{'crc'}, 'ok', "CRC ok";
DEBUG Dumper($data);

# Testing rain invalid packet
$input = $dut->_create_data('E005D734010F8AFA0000');
$data = $dut->decode($input);
DEBUG Dumper($data);

is $data->{'rain'}->{'current'}, 0, "No rain counted";


$input = $dut->_create_data('E00F6C69020020E00000');
$data = $dut->decode($input);
is $data->{crc}, 'fail, expected 9BB9', "CRC fail as expected";


$input = $dut->_create_data('E004B6340302B802ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";
is $data->{'rain'}->{'current'}, 0, "No rain counted";

INFO $data->{crc};

$input = $dut->_create_data('6006d3ffc0007875ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";
DEBUG Dumper($data);

# Test CRC on example packets of Dekay in forum
## First a failed packet
$input = $dut->_create_data('63763dd941787c33ffff');
$data = $dut->decode($input);
is $data->{crc}, 'fail, expected 6EF3', "CRC check fails as expected";

$input = $dut->_create_data('80080c0ab900fa6bffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('e0090a4703008681ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('50080aff7300887bffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('a0060a8c3b00d352ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('8009080ab9009acbffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('e00a0947010095edffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('500d0fff7100710bffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";

$input = $dut->_create_data('a00b0f8c3b004e6dffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";
$input = $dut->_create_data('800c0f0abb008ed3ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass";


$input =$dut->_create_data('E000B237010D3528ffff');
$data = $dut->decode($input);
is $data->{crc}, 'ok', "CRC check pass input log";

$input =$dut->_create_data('DD00B939575E8B9Dffff');
$data = $dut->decode($input);
is $data->{crc}, 'fail, expected 9F76', "CRC fail as expected";


DEBUG Dumper($data);


done_testing();