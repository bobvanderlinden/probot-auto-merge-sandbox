#!/usr/bin/env bash
# set -x
set -o errexit

file="$1"
content="$2"

owner="bobvanderlinden"
repo="probot-auto-merge-sandbox"

github_curl()
{
  curl --silent --fail --header 'Accept: application/vnd.github.v3+json' --header "Authorization: token $GITHUB_TOKEN" "$@"
}

# base_file_Sha="$(github_curl "https://api.github.com/repos/$owner/$repo/contents/$file" | jq -r .sha)"
# if [[ "$base_file_Sha" = "null" ]]
# then
#   base_file_Sha=""
# fi
content_base64="$(echo "$content" | base64)"

base_branch="${base_branch:-master}"
head_branch="${head_branch:-pr-update-$RANDOM}"
base_sha="$(github_curl "https://api.github.com/repos/$owner/$repo/git/refs/heads/$base_branch" | jq -r .object.sha)"

commit_message="${commit_message:-Update $file to $content}"
pull_request_title="${pull_request_title:-$commit_message}"
pull_request_body="${pull_request_body:-$commit_message}"

# Create branch
github_curl -X POST "https://api.github.com/repos/$owner/$repo/git/refs" --header "Content-Type: application/json" --data @- << EOF
{
  "ref": "refs/heads/$head_branch",
  "sha": "$base_sha"
}
EOF

# Write file on branch
github_curl -X PUT "https://api.github.com/repos/$owner/$repo/contents/$file" --header "Content-Type: application/json" --data @- << EOF
{
  "message": $(echo "$commit_message" | jq -R .),
  "content": "$content_base64",
  "branch": "$head_branch"
}
EOF

# Create pull request
github_curl -X POST "https://api.github.com/repos/$owner/$repo/pulls" --header "Content-Type: application/json" --data @- << EOF
{
  "title": $(echo "$pull_request_title" | jq -R .),
  "body": $(echo "$pull_request_body" | jq -R .),
  "head": "$head_branch",
  "base": "$base_branch"
}
EOF
