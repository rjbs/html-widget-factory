
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
  my ($self, $factory, $arg) = @_;

  my @widgets;

  $self->validate_value($arg->{value}, $arg->{options});
  $arg->{attr}{name} ||= $arg->{attr}{id};

  for my $option (@{ $arg->{options} }) {
    my ($value, $text, $id) = (ref $option) ? (@$option) : (($option) x 2);

    my $widget = HTML::Element->new('input', type => 'radio');
    $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };
    # XXX document
    $widget->attr(id => $id) if $id;
    $widget->attr(value => $value);
    $widget->push_content(HTML::Element->new('~literal', text => $text));

    $widget->attr(checked => 'checked')
      if $arg->{value} and $arg->{value} eq $value;

    push @widgets, $widget;
  }

  # XXX document
  return @widgets if wantarray and $arg->{parts};

  return join '', map { $_->as_XML } @widgets;
}

=head2 C< validate_value >

This method checks whether the given value option is valid.  See C<L</radio>>
for an explanation of its default rules.

=cut

sub validate_value {
  my ($class, $value, $options) = @_;

  my @options = map { ref $_ ? $_->[0] : $_ } @$options;
  # maybe this should be configurable?
  if ($value) {
    my $matches = grep { $value eq $_ } @options;

    if (not $matches) {
      Carp::croak "provided value '$matches' not in given options: "
                . join(' ', map { "'$_'" } @options);
    } elsif ($matches > 1) {
      Carp::croak "provided value '$matches' matches more than one option";
    }
  }
}

=head1 AUTHOR

Ricardo SIGNES <C<rjbs @ cpan.org>>

=head1 COPYRIGHT

Copyright (C) 2005, Ricardo SIGNES.  This is free software, released under the
same terms as perl itself.

=cut

1;
