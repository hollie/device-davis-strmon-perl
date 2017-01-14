use strict;
use warnings;
package Device::Davis::Strmon;

# ABSTRACT: Parser for the Davis ISS output of the STRMON command
# VERSION

use Moose;
use namespace::autoclean;
use autodie;
use Log::Log4perl qw(:easy);
use List::Util qw(any);
use Math::Units qw(convert);

has verbose => (
    is      => 'ro',
    isa     => 'Int',
    default => '0',
);

# Actions that need to be run after the constructor
sub BUILD {
    my $self = shift;
    # Add stuff here
}

sub decode {
	my $self = shift();
	my $input = shift();
	
	# Check the formatting of the input
	$self->_check_format($input);
	
	# Extract the useful data from the packet
	my $data = $self->_extract_data($input);
	
	my $result = $self->_parse_data($data);
}

# Basic sanity check on the received input
sub _check_format {
	
	my $self = shift();
	my $input = shift();
	
	if (! ($input =~ /\n\r\n\r$/g )) {
		LOGCROAK "Input string does not contain the expected end of line";
	}
	
	my @valid_packets = [ 2 .. 9, 'a', 'e' ];

	if ($input =~ /0\s+=\s+([[:xdigit:]])[[:xdigit:]]\r\n/g ) {
		# Ensure we don't try to process packets that we don't understand
		if (!(any {$_ eq $1 } @valid_packets )) {
			LOGCARP "Packet type $1 not supported yet";
		} 
	}
}

# Extract the useful data from the overly chatty format
sub _extract_data {
	
	my $self = shift();
	my $input = shift();
	
	my @bytes = split(/\n\r/, $input);
	my $raw;
	foreach (@bytes) {
		if ($_ =~ /\d\s+=\s+([[:xdigit:]]+)/){
			push @{$raw}, hex($1);
			#sprintf("%02X", hex($1));	
		} else {
			LOGDIE "Invalid input entry '$_'";
		}
	}
	
	return $raw;
}

# Actual parsing of the data
sub _parse_data {
	
	my $self = shift();
	my $input = shift();
	
	#print $input . "\n";

	# Fetch the header byte to determine the packet type
	my $header = $input->[0] / 16;
	
	my $data;
	
	# Fetch wind speed
	$data->{windSpeed} = convert($input->[1], 'mi', 'km');
	# Fetch wind direction
	if ($input->[2] == 0) {
  		$data->{windDirection} = 360;
	} else {
  		$data->{windDirection} = ($input->[2] * 1.40625) + .3;
	}
	
	if ($header eq '2') {
		$data->{capVoltage} = (($input->[3] * 4) + (($input->[4] && 0xC0) / 64)) / 100
	}
		
	if ($header eq '7') {
		$data->{solar} = $input->[3] * 4 + ($input->[4] && 0xC0) / 64;
		DEBUG "Solar cell info packet detected: $data->{solar}";
	}	
	
	if ($header eq '8') {
		$data->{temperature} = ((($input->[3] * 256 + $input->[4]) / 160) - 32) * 5 / 9
	}
	
	if ($header eq '9') {
		$data->{windGust} = convert($input->[3], 'mi', 'km');
	}
	
	if ($header eq 'a') {
		$data->{humidity} = ((($input->[4] && 0xF0) * 16) + $input->[3]) / 10
	}
	
	return $data;	
}

# Speed up the Moose object construction
__PACKAGE__->meta->make_immutable;
no Moose;
1;


=head1 SYNOPSIS

my $object = Device::Davis::Strmon->new();

=head1 DESCRIPTION

This module is the protocol parser for the output of the Davis ISS data received after sending 'STRMON' to the console.
I'm using this in combination with the ISS packet receiver written by Dekay to fetch data from my weather station and to 
feed it into my home automation system.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Device::Davis::Strmon object. Supported parameters are listed below

=over

=item verbose

Allows to set the verbosity level of the module.

=back

=head2 C<decode($input)>

Takes a raw string as received over the serial port and returns the information in the packet as a hash. The actual contents of the return
values of course depend on the packet that was received.

Note: output from the device after sending STRMON looks like:

0 = 50

1 = 0

2 = B4

3 = FF

4 = 73

5 = C

6 = 18

7 = 51

8 = FF

9 = FF

Every line is separated with a 0x0A 0x0D. The string is terminaled with two consecutive 0x0A 0x0D sequences. This is validated in the module.

=head2 BUILD

Helper function to run custome code after the object has been created by Moose.

=head2 CREDITS

Major thanks to Dekay and Darios who did all of the reverse engineering of the packets. References:

* https://www.carluccio.de/davis-vue-hacking-part-2/
* https://github.com/dekay/DavisRFM69/wiki/Message-Protocol
=cut

