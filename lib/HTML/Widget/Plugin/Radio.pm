
use strict;
use warnings;

package HTML::Widget::Plugin::Radio;
use base qw(HTML::Widget::Plugin);

=head1 NAME

HTML::Widget::Plugin::Radio - a widget for sets of radio buttons

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This plugin provides a radio button-set widget

=cut

use HTML::Element;

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: radio

=cut

sub provided_widgets { qw(radio) }

=head2 C< radio >

This method returns a set of radio buttons.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item disabled

If true, this option indicates that the select widget can't be changed by the
user.

=item options

This option must be a reference to an array of allowed values, each of which
will get its own radio button.

=item value

If this argument is given, the option with this value will be pre-selected in
the widget's initial state.

An exception will be thrown if more or less than one of the provided options
has this value.

=back

=cut

sub _attribute_args { qw(disabled) }
sub _boolean_args   { qw(disabled) }

sub radio {
  my $self   = shift;
  my $factor = shift;
  my $arg = $self->rewrite_arg(shift);

  my @widgets;

  $self->validate_value($arg->{value}, $arg->{options});

  for my $option (@{ $arg->{options} }) {
    my $widget = HTML::Element->new('input', type => 'radio');
    $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };
    $widget->attr(value => $option);

    $widget->attr(on => 'on') if $arg->{value} and $arg->{value} eq $option;

    push @widgets, $widget;
  }

  return join '', map { $_->as_HTML } @widgets;
}

=head2 C< validate_value >

This method checks whether the given value option is valid.  See C<L</radio>>
for an explanation of its default rules.

=cut

sub validate_value {
  my ($class, $value, $options) = @_;

  # maybe this should be configurable?
  if ($value) {
    my $matches = grep { $value eq $_ } @$options;
    Carp::croak "provided value not in given options" unless $matches;
    Carp::croak "provided value matches more than one option" if $matches > 1;
  }
}

=head1 AUTHOR

Ricardo SIGNES <C<rjbs @ cpan.org>>

=head1 COPYRIGHT

Copyright (C) 2005, Ricardo SIGNES.  This is free software, released under the
same terms as perl itself.

=cut

1;