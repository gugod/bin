#!/bin/bash

if [[ -z "$(docker images | grep '^gugod/perlcritic')" ]]; then
    docker pull gugod/perlcritic 1>&2
fi

function _perlcritic() {
    # docker run -it --mount src="$(pwd)",target="/code",type=bind -w /code gugod/perlcritic:latest perlcritic $*
    docker run -it -v $(pwd):/code -w /code gugod/perlcritic:latest perlcritic "$@"
}

if [[ -n "$*" ]]; then
    _perlcritic "$@"
    exit
fi

opts=
if [[ -f .perlcriticrc ]]; then
    opts="--profile .perlcriticrc"
fi

_perlcritic $opts --list-enabled 1>&2
_perlcritic $opts $(find . -name '*.psgi') $(find . -name '*.p[ml]') $(find . -name '*.t')

