#!/bin/bash

# Script to update all issues according to the new Lastenheft v3

# Fetch all issues from the repository
issues=$(gh issue list --json number,title --jq '.[] | {number: .number, title: .title}')

# New specifications from Lastenheft v3
new_specifications="New specifications based on Lastenheft v3"

# Loop through each issue and update accordingly
for issue in $(echo "$issues" | jq -c '.'); do
    issue_number=$(echo $issue | jq -r '.number')
    issue_title=$(echo $issue | jq -r '.title')

    # Creating the update message
    update_message="Updating issue #$issue_number: $issue_title\n\n$new_specifications"

    # Update the issue using GitHub CLI
    gh issue edit $issue_number --body "$update_message"
done

echo "All issues have been updated according to Lastenheft v3."