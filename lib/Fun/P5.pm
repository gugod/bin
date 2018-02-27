package Fun::P5;
use v5.18;
use strict;
use warnings;

use Data::Dumper qw'Dumper';
use PPI;
use PPI::Document;
use PPI::Token::Word;
use PPI::Token::Operator;
use PPI::Token::Whitespace;
use PPI::Token::Quote::Single;
use PPIx::Literal;

use Exporter 'import';
our @EXPORT_OK = qw(inject_include);

# Idempotent
sub inject_include {
    my ($doc, $module, @imports) = @_;

    my $include = 'use ' . $module . (@imports ? (' qw(' . join(' ', @imports) . ')') : '') . ";\n\n";
    my ($el_include) = PPI::Document->new(\$include);

    my $injected;
    my %used_modules;
    my $preamble_started;
    my $preamble_ended;
    my @children = $doc->schildren();
    for my $o (@children) {
        if ($o->isa('PPI::Statement::Include')) {
            my $m = $o->module;
            if ($m eq $module) {
                inject_module_imports($o, @imports);
                $injected = 1;
                last;
            }
        }
        if ($preamble_started) {
            if (!$o->isa('PPI::Statement::Include')) {
                $preamble_ended = $o;
                last;
            }
        } else {
            if ($o->isa('PPI::Statement::Include')) {
                $preamble_started = $o;
            }
        }
    }

    if (!$injected && $preamble_started && $preamble_ended) {
        $doc->__insert_before_child(
            $preamble_ended,
            $el_include
        );
    }
}

# Idempotent
sub inject_module_imports {
    my ($el_include, @imports) = @_;

    my @args = $el_include->arguments;
    if (@imports > 0) {
        if (@args == 0) {
            my $new_imports = PPI::Document->new(\(' qw(' . join(" ", @imports) . ')'));

            my $semi = $el_include->find_first('Token::Structure');
            $semi->insert_before( $new_imports );

        } elsif (@args == 1) {
            my @literals = PPIx::Literal->convert(@args);
            my %imported = map { $_ => 1 } @literals;

            if ($args[0]->isa('PPI::Token::QuoteLike::Words')) {
                my @words = @literals;
                for my $x (@imports) {
                    push(@words, $x) unless $imported{$x};
                }

                my ($left, $right) = (split(//, [$args[0]->_delimiters]->[0]), '');

                $args[0]->set_content('qw' . $left . join(" ", @words) . $right);
            } elsif ($args[0]->isa('PPI::Structure::List')) {
                for my $x (@imports) {
                    next if $imported{$x};
                    for my $t (
                        PPI::Token::Operator->new(','),
                        PPI::Token::Whitespace->new(' '),
                        PPI::Token::Quote::Single->new("'$x'"),
                    ) {
                        say "Append $t";
                        $args[0]->add_element($t);
                    }
                }
            } else {
                say "I failed at trying to deal with:\n    $el_include\n";
                ...
            }
        } elsif (@args > 1) {
            ...
        }
    }
}
