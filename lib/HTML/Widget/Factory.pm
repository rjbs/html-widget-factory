use 5.006;
use strict;
use warnings;
package HTML::Widget::Factory;
# ABSTRACT: churn out HTML widgets

use MRO::Compat;

=head1 SYNOPSIS

 my $factory = HTML::Widget::Factory->new();

 my $html = $factory->select({
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

use Module::Pluggable 2.9
  search_path => [ qw(HTML::Widget::Plugin) ],
  sub_name    => '_default_plugins',
  except      => qr/^HTML::Widget::Plugin::Debug/;

use Package::Generator 0.100;
use Package::Reaper 0.100;

=head1 METHODS

Most of the useful methods in an HTML::Widget::Factory object will be installed
there by its plugins.  Consult the documentation for the HTML::Widget::Plugin
modules.

=head2 new

  my $factory = HTML::Widget::Factory->new(\%arg);

This constructor returns a new widget factory.

The only valid arguments are C<plugins> and C<extra_plugins>, which provide
arrayrefs of plugins to be used.  If C<plugins> is not given, the default
plugin list is used; this is generated by finding all modules beginning with
HTML::Widget::Plugin.  The plugins in C<extra_plugins> are loaded in addition
to these.

=cut

sub __new_class {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $obj_class = Package::Generator->new_package({
    base => "$class\::GENERATED",
    isa  => $class,
  });
}

sub __mix_in {
  my ($class, @plugins) = @_;

  for my $plugin (@plugins) {
    unless ($plugin =~ /::(__)?GENERATED\1::/ and
              Package::Generator->package_exists($plugin)) {
      eval "require $plugin; 1" or die $@; ## no critic Carp
    }

    my @widgets = $plugin->provided_widgets;

    for my $widget (@widgets) {
      my $install_to = $widget;
      ($widget, $install_to) = @$widget if ref $widget;

      # XXX: This is awkward because it checks ->can instead of provides_widget.
      # This may be for the best since you don't want a widget called "new"
      # -- rjbs, 2008-05-06
      # Carp::croak "$class can already provide widget '$widget'"
        # if $class->can($install_to);

      Carp::croak
        "$plugin claims to provide widget '$widget' but has no such method"
        unless $plugin->can($widget);

      {
        no strict 'refs';
        my $pw = \%{"$class\::_provided_widgets"};
        $pw->{ $install_to } = 1;
      }

      Sub::Install::install_sub({
        into => $class,
        as   => $install_to,
        code => $class->_generate_widget_method({
          plugin => $plugin,
          widget => $widget,
        }),
      });
    }
  }
}

sub _generate_widget_method {
  my (undef, $arg) = @_;
  my $plugin = $arg->{plugin};
  my $widget = $arg->{widget};
  return sub {
    my ($self, $given_arg) = @_;
    my $arg = $plugin->rewrite_arg($given_arg);

    $plugin->$widget($self, $arg);
  }
}

my %_default_class;

sub _default_class {
  $_default_class{ $_[0] } ||= do {
    my $base  = $_[0];
    my $class = $base->__new_class;
    $class->__mix_in($base->_default_plugins);
    $class;
  };
}

my %default_instance;
sub _default_instance {
  $default_instance{ $_[0] } ||= $_[0]->default_class->new;
}

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $obj_class = ref $class ? (ref $class) : $class->_default_class;

  my @plugins = $arg->{plugins}
              ? @{ $arg->{plugins} }
              : $class->_default_plugins;

  unshift @plugins, @{ $class->{plugins} } if ref $class;

  if ($arg->{plugins} or $arg->{extra_plugins}) {
    $obj_class = $class->__new_class;

    push @plugins, @{ $arg->{extra_plugins} } if $arg->{extra_plugins};

    $obj_class->__mix_in(@plugins);
  }

  # for some reason PPI/Perl::Critic think this is multiple statements:
  bless { ## no critic
    plugins => \@plugins,
  } => $obj_class;
}

=head2 provides_widget

  if ($factory->provides_widget($name)) { ... }

This method returns true if the given name is a widget provided by the factory.
This, and not C<can> should be used to determine whether a factory can provide
a given widget.

=cut

sub provides_widget {
  my ($self, $name) = @_;
  $self = $self->_default_instance unless ref $self;

  for my $plugin (@{ $self->{plugins} }) {
    # XXX: replace with something much faster, by mapping (name => method) at
    # initialization time
    my @provided = map  { ref $_ ? $_->[1] : $_ } $plugin->provided_widgets;
    return 1 if grep { $name eq $_ } @provided;
  }

  return;
}

=head2 provided_widgets

  for my $name ($fac->provided_widgets) { ... }

This method returns an unordered list of the names of the widgets provided by
this factory.

=cut

sub provided_widgets {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my %provided;

  for (@{ mro::get_linear_isa($class) }) {
    no strict 'refs';
    my %pw = %{"$_\::_provided_widgets"};
    @provided{ keys %pw } = (1) x (keys %pw);
  }

  return keys %provided;
}


=head2 plugins

This returns a list of the plugins loaded by the factory.

=cut

sub plugins { @{ $_[0]->{plugins} } }

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

=item L<HTML::Widget::Plugin::Submit>

=item L<HTML::Widget::Plugin::Link>

=item L<HTML::Widget::Plugin::Image>

=item L<HTML::Widget::Plugin::Password>

=item L<HTML::Widget::Plugin::Select>

=item L<HTML::Widget::Plugin::Multiselect>

=item L<HTML::Widget::Plugin::Checkbox>

=item L<HTML::Widget::Plugin::Radio>

=item L<HTML::Widget::Plugin::Button>

=item L<HTML::Widget::Plugin::Textarea>

=item L<HTML::Element>

=back

=cut

1;
