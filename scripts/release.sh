#!/usr/bin/env bash

set -o errexit
set -o nounset

function usage()
{
  echo "Usage: $0 <[options]>"
  echo "Options:"
  echo "    --local-repo <PATH>"
  echo "    --remote-repo <GITHUB_URL>"
  echo "    --dry-run"
}

DRY_RUN=false
LOCAL_REPO=$HOME/tarides-opam-repository
REMOTE_REPO=git@github.com:gpetiot/tarides-opam-repository

options=$@
arguments=($options)
index=0

for argument in $options; do
  index=`expr $index + 1`

  case $argument in
    --local-repo)
      LOCAL_REPO="${arguments[index]}"
      ;;
    --remote-repo)
      REMOTE_REPO="${arguments[index]}"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --help)
      usage
      exit 2
      ;;
  esac
done

echo "Running config:"
echo "- DRY_RUN: $DRY_RUN"
echo "- LOCAL_REPO: $LOCAL_REPO"
echo "- REMOTE_REPO: $REMOTE_REPO"

read -p "Continue? [Y/n]" -n 1
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo "Canceled by user."
  exit 1
fi

DRY_RUN=$([ $DRY_RUN == true ] && echo "--dry-run" || echo "")

DIST_URI=https://github.com/tarides/opam-repository/raw/master/packages/caretaker

dune-release distrib $DRY_RUN
dune-release publish $DRY_RUN

TARBALL=$(dune-release delegate-info tarball)
VERSION=$(dune-release delegate-info tarball | cut -d'-' -f2 | cut -d'.' -f '-3')

dune-release opam pkg \
	--dist-uri $DIST_URI/caretaker.$VERSION/caretaker-$VERSION.tbz \
  $DRY_RUN

cp -R _build/caretaker.$VERSION $LOCAL_REPO/packages/caretaker
cp $TARBALL $LOCAL_REPO/packages/caretaker/caretaker.$VERSION

dune-release opam submit \
  --opam-repo tarides/opam-repository \
  --remote-repo $REMOTE_REPO \
  --local-repo $LOCAL_REPO \
  $DRY_RUN
