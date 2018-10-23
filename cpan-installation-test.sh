#!/bin/bash

PERL_INSTALLATION=v28
LOGDIR=~/var/cpan-installation-test

if [[ ! -d $LOGDIR ]]; then mkdir -p $LOGDIR; fi

eval "$(perlbrew init-in-bash)"
perlbrew use ${PERL_INSTALLATION}

function run_with_timeout () {
    local time=10
    if [[ $1 =~ ^[0-9]+$ ]]; then time=$1; shift; fi
    # Run in a subshell to avoid job control messages
    ( "$@" &
      child=$!
      # Avoid default notification in non-interactive shell for SIGTERM
      trap -- "" SIGTERM
      ( sleep $time
        kill $child 2> /dev/null ) &
      wait $child
    )
}

function test_one_dist {

    local dist=$1
    local distdir=$(echo $dist | perl -p -e 's/[^0-9A-Za-z\.]+/-/gi; s/\A-+//; s/-+\z//;')
    local lib_name="${PERL_INSTALLATION}@cpan_installation_test_${RANDOM}"

    perlbrew list-modules | grep -v '^Perl$' | cpanm --uninstall -f

    (
        echo "Perlbrew"
        echo "========"
        perlbrew info
        echo "========"

        echo ">>> Use ${lib_name} for $dist";
        perlbrew lib create $lib_name
        perlbrew use $lib_name

        echo "--- cpanm $dist";
        run_with_timeout 60 cpanm $dist
        rc=$?
        echo "--- done"

        if [[ $rc -eq 0 ]]; then
            touch $LOGDIR/${distdir}-cpanm.ok
        else
            touch $LOGDIR/${distdir}-cpanm.fail
        fi

        perlbrew list-modules > $LOGDIR/${distdir}-installed.log
        perlbrew use ${PERL_INSTALLATION}
        perlbrew lib delete $lib_name
        echo "<<< DELETED ${lib_name}";
    ) > $LOGDIR/${distdir}.log 2>&1
}

# MODULES=$(echo Elastijk App::csv2tsv yagg URI::Fast Test::Locus grepmail)
# MODULES=$(echo Search::Xapian App::unichar App::sdif Getargs::Long FileHandle::Unget Net::Stripe)
for dist in $*
do
    test_one_dist $dist
done
