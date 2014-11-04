#!/bin/sh

if [ -z "$APP_ROOT" ]; then
    echo "set APP_ROOT before running"
    exit
fi

if [ -z "$PERL" ]; then
    PERL="/usr/bin/perl"
fi
if [ -z "$CPANM" ]; then
    CPANM="$PERL $HOME/perl5/perlbrew/bin/cpanm"
fi

echo "USING PERL=$PERL";
echo "USING CPANM=$CPANM";


BIN_BASE=${APP_ROOT}/bin
DEP_BASE=${APP_ROOT}/dep
APP_BASE=${APP_ROOT}/app

mkdir -p $BIN_BASE $DEP_BASE $APP_BASE

export PERL5LIB=$APP_BASE/lib/perl5:$DEP_BASE/lib/perl5
${CPANM} -L $DEP_BASE Module::Install Module::Install::CPANfile
${CPANM} -L $DEP_BASE --installdeps .
${PERL} Makefile.PL INSTALL_BASE=$APP_BASE
make &&  make install

for executable in $APP_BASE/bin/*
do
    this_executable=$BIN_BASE/`basename $executable`
    echo "#!/bin/sh
export PERL5LIB=$APP_BASE/lib/perl5:$DEP_BASE/lib/perl5
exec $PERL $executable \$@" > $this_executable
    chmod +x $this_executable
done
