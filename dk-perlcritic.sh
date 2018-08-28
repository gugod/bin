#!/bin/bash

docker pull gugod/perlcritic

function _perlcritic() {
    # docker run -it --mount src="$(pwd)",target="/code",type=bind -w /code gugod/perlcritic:latest perlcritic $*
    docker run -it -v $(pwd):/code -w /code gugod/perlcritic:latest perlcritic $*
}

if [[ -n "$*" ]]; then
    _perlcritic $*
else
    _perlcritic --profile .perlcriticrc --list-enabled
    _perlcritic --profile .perlcriticrc $(find . -name '*.psgi') $(find . -name '*.p[ml]') $(find . -name '*.t') 
fi
