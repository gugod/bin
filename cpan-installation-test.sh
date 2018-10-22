#!/bin/bash

PERL_INSTALLATION=v28
LOGDIR=~/var/log/cpan-installation-test

PERL_CPANM_OPT=${PERL_CPANM_OPT:-}
PERL_CPANM_OPT=${PERL_CPANM_OPT/--notest//}
echo PERL_CPANM_OPT=$PERL_CPANM_OPT

if [[ ! -d $LOGDIR ]]; then mkdir -p $LOGDIR; fi

eval "$(perlbrew init-in-bash)"
perlbrew use ${PERL_INSTALLATION}
perlbrew list-modules | grep -v '^Perl$' | cpanm --uninstall -f

echo "Perlbrew"
echo "========"
perlbrew info
echo "========"

function test_one_dist {
    local dist=$1
    local distdir=$(echo $dist | perl -p -e 's/[^0-9A-Za-z\.]+/-/gi')
    local lib_name="${PERL_INSTALLATION}@cpan_installation_test_${RANDOM}"

    echo ">>> Use ${lib_name} for $dist";
    perlbrew lib create $lib_name
    perlbrew use $lib_name

    echo "--- cpanm $dist";
    cpanm --verbose $dist > $LOGDIR/${distdir}-cpanm.log 2>&1
    echo "--- done"

    rc=$?
    if [[ $rc -eq 0 ]]; then
        touch $LOGDIR/${distdir}-cpanm.ok
    else
        touch $LOGDIR/${distdir}-cpanm.fail
    fi

    perlbrew list-modules > $LOGDIR/${distdir}-installed.log
    perlbrew use ${PERL_INSTALLATION}
    perlbrew lib delete $lib_name
    echo "<<< DELETED ${lib_name}";
}

# MODULES=$(echo Elastijk App::csv2tsv yagg URI::Fast Test::Locus grepmail)
# MODULES=$(echo Search::Xapian App::unichar App::sdif Getargs::Long FileHandle::Unget Net::Stripe)
for dist in $*
do
    test_one_dist $dist
done
