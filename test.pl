package main;

use AnyEvent 5;
use lib::abs 'lib';
use AE::Tx;

my $cv = AE::Tx;

$cv->begin;

my $tx1 = $cv->begin('zzzz');
my $t;$t = AnyEvent->timer(after => 0.1, cb => sub {
	undef $t;
	$tx1->end;
});

my $tx2 = $cv->begin('bad');
my $t;$t = AnyEvent->timer(after => 0.5, cb => sub {
	undef $t;
	$cv->send;
});

$cv->recv;
print $cv->state;
