#! /usr/bin/env bash

set -e

cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

mr=$1
glab="glab --repo fdroid/fdroiddata"
echo "Rebasing..."
$glab mr rebase $mr --skip-ci
while [[ $($glab mr view $mr -F json | jq -r '.detailed_merge_status') != "mergeable" ]]; do
  echo "Checking status..."
  continue
done
echo "Merging..."
$glab mr merge $mr --auto-merge=false --rebase --yes && {
  echo "Canceling pipelines..."
  merged_commit=$($glab mr view $mr -F json | jq -r 'if .squash then .squash_commit_sha else .sha end')
  head_pipelines=$($glab ci list -F json | jq -r 'map(select(.sha == "'$merged_commit'" and (.source == "push" or .source == "merge_request_event")) | .id)[]')
  for pipeline in $head_pipelines; do
    glab api --method POST --silent projects/:id/pipelines/$pipeline/cancel
  done
  echo "Done!"
} || echo "Merge failed: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/$mr"
