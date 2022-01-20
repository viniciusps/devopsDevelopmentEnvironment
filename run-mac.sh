#!/bin/bash

BREW_PKGS="vagrant vagrant-manager virtualbox"

for pkg in $BREW_PKGS; do
    brew list $pkg
    if [ ! $? = 0 ]; then
        brew install $pkg
    fi
done

source ./config.env

vagrant up