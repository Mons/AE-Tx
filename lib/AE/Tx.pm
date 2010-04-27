{
	package AE::Tx::Single;
	
	sub new {
		my $self = bless {},shift;
		$self->{cb} = shift;
		$self->{cl} = shift;
		$self->{name} = shift;
		$self;
	}
	
	sub at { join ' line ', @{ shift->{cl} }[1,2] }
	
	sub end {
		my $self = shift;
		$self->{cb} and $self->{cb}->();
		delete $self->{cb};
		return;
	}
	
	sub DESTROY {
		shift->end;
	}
	
	package AE::Tx;
	
	use Scalar::Util qw(weaken);
	use AnyEvent 5;
	use Carp;
	
	sub new {
		my $self = bless {},shift;
		$self->{cv} = AE::cv;
		$self->{tx} = {};
		$self->{send} = '';
		$self;
	}
	
	sub begin {
		weaken(my $self = shift);
		defined wantarray or return carp "Tx object not stored";
		#warn "++";
		$self->{cv}->begin;
		my $name = shift;
		
		my $id;
		my $tx = AE::Tx::Single->new(sub {
			$self or return;
			delete $self->{tx}{$id};
			#warn "--";
			$self->{cv}->end;
		}, [caller], $name );
		$id = int $tx;
		weaken( $self->{tx}{$id} = $tx );
		return $tx;
	}
	sub end {
		carp "end must be called on tx, not on me";
	}
	
	sub send {
		my $self = shift;
		$self->{send} = "send was called at ".join(' line ',(caller)[1,2]).' ';
		$self->{cv}->send(@_);
	}
	sub recv {
		my $self = shift;
		$self->{cv}->recv(@_);
	}
	
	sub ok {
		my $self = shift;
		!%{$self->{tx}}
	}
	
	sub state {
		my $self = shift;
		my $rv = '';
		for (values %{$self->{tx}}) {
			defined or next;
			$rv .= "not finished tx".($_->{name} ? "($_->{name})":'').", started at ".$_->at."; $self->{send}\n";
		}
		$rv;
	}
	
	sub AE::Tx () {
		return AE::Tx->new();
	};
}

1;
