#!/bin/sh
set -x
set -e
clear

git rm -rf lib/forge-std
git rm -rf lib/foundry-devops
rm -rf lib/forge-std
forge install foundry-rs/forge-std@v1.8.2 --no-commit
rm -rf lib/foundry-devops
forge install Cyfrin/foundry-devops --no-commit