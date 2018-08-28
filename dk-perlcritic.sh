#!/bin/bash

docker pull gugod/perlcritic

function _perlcritic() {
    # docker run -it --mount src="$(pwd)",target="/code",type=bind -w /code gugod/perlcritic:latest perlcritic $*
    docker run -it -v $(pwd):/code -w /code gugod/perlcritic:latest perlcritic $*
}

if [[ -n "$*" ]]; then
    exec _perlcritic $*
fi

opts=
if [[ -f .perlcriticrc ]]; then
	opts="--profile .perlcriticrc"
fi

_perlcritic $opts --list-enabled
exec _perlcritic $opts $(find . -name '*.psgi') $(find . -name '*.p[ml]') $(find . -name '*.t')

