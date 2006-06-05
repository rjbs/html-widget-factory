
use strict;
use warnings;

package HTML::Widget::Factory;

=head1 NAME

HTML::Widget::Factory - churn out HTML widgets

=head1 VERSION

version 0.03_01

 $Id$

=cut

our $VERSION = '0.03_01';

=head1 SYNOPSIS

 my $widget = HTML::Widget::Factory->new();

 my $html = $widget->select({
   name    => 'flavor',
   options => [
     [ minty => 'Peppermint',     ],
     [ perky => 'Fresh and Warm', ],
     [ super => 'Red and Blue',   ],
   ],
   value   => 'minty',
 });

=head1 DESCRIPTION

HTML::Widget::Factory provides a simple, pluggable system for constructing HTML
form controls.

=cut

use Module::Pluggable
  search_path => [ qw(HTML::Widget::Plugin) ],
  sub_name    => '_default_plugins';

use Package::Generator;
use Package::Reaper;
use UNIVERSAL::require;

=head1 METHODS

Most of the useful methods in an HTML::Widget::Factory object will be installed
there by its plugins.  Consult the documentation for the HTML::Widget::Plugin
modules.

=head2 new

This constructor returns a new widget factory.  It ignores all its arguments.

=cut

sub __new_class {
  my ($class) = @_;

  my $obj_class = Package::Generator->new_package({
    base => "$class\::GENERATED",
    isa  => $class,
  });
}

sub __mix_in {
  my ($class, @plugins) = @_;

  for my $plugin (@plugins) {
    $plugin->require or die $@;
    $plugin->import({ into => $class });
  }
}

my @_default_plugins;
my $_default_class;
BEGIN {
  @_default_plugins = __PACKAGE__->_default_plugins;

  $_default_class = __PACKAGE__->__new_class;

  $_default_class->__mix_in(@_default_plugins);
}

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $obj_class = $_default_class;
  my $reaper;

  if ($arg->{plugins} or $arg->{extra_plugins}) {
    $obj_class = $class->__new_class;

    my @plugins = $arg->{plugins} ? @{ $arg->{plugins} } : @_default_plugins;

    push @plugins, @{ $arg->{extra_plugins} } if $arg->{extra_plugins};

    $obj_class->__mix_in(@plugins);

    $reaper = Package::Reaper->new($obj_class);
  }

  bless { ($reaper ? (reaper => $reaper) : ()) } => $obj_class;
}

=head1 TODO

=over

=item * fixed_args for args that are fixed, like (type => 'checkbox')

=item * a simple way to say "only include this output if you haven't before"

This will make it easy to do JavaScript inclusions: if you've already made a
calendar (or whatever) widget, don't bother including this hunk of JS, for
example.

=item * giving the constructor a data store

Create a factory that has a CGI.pm object and let it default values to the
param that matches the passed name.

=item * include id attribute where needed

=item * optional labels (before or after control, or possibly return a list)

=back

=head1 SEE ALSO

=over

=item L<HTML::Widget::Plugin>

=item L<HTML::Widget::Plugin::Input>

=item L<HTML::Widget::Plugin::Link>

=item L<HTML::Widget::Plugin::Password>

=item L<HTML::Widget::Plugin::Select>

=item L<HTML::Widget::Plugin::Multiselect>

=item L<HTML::Widget::Plugin::Checkbox>

=item L<HTML::Widget::Plugin::Radio>

=item L<HTML::Widget::Plugin::Textarea>

=item L<HTML::Element>

=back

=head1 AUTHOR

Ricardo SIGNES <C<rjbs @ cpan.org>>

=head1 COPYRIGHT

Copyright (C) 2005, Ricardo SIGNES.  This is free software, released under the
same terms as perl itself.

=cut

1;

