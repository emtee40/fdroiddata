#! /usr/bin/env bash

set -e

cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

glab="glab --repo fdroid/fdroiddata"
mr_list=$($glab mr list --author checkupdates-bot -F json | jq -r 'map(.iid)[]')
for mr in $mr_list; do
  if [[ $($glab mr view $mr -F json | jq -r '.pipeline.status') == "success" ]]; then
    echo "Merging $mr..."
    ./tools/auto-merge.sh $mr
  fi
done
