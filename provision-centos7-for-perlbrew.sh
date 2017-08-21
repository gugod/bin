#!/bin/bash

export PERLBREW_ROOT="/usr/local/perlbrew"
mkdir -p $PERLBREW_ROOT

yum upgrade -y
yum install -y epel-release
yum install -y htop nginx git bzip2 gcc

cd /tmp

curl -L https://install.perlbrew.pl -o install_perlbrew.sh && sh -x install_perlbrew.sh

source ${PERLBREW_ROOT}/etc/bashrc

perlbrew install -n -j2 --as v24 perl-5.24.1
perlbrew install-cpanm
perlbrew use v24
