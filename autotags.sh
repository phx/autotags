#!/bin/bash

set -e

FILE="${FILE:-"tags.csv"}"
RESOURCES="${RESOURCES:-"${@:2}"}"

usage() {
  echo "
Usage: $0 [API] [RESOURCES]

\$API and \$RESOURCES can also be specified as environment variables.

Note: If \$API is specified as an environment variable,
      the first argument must include the word 'resource' or 'arn',
      followed by the resources you wish to tag.

By default, $0 looks for 'tags.csv' in the current directory.
If you wish to use a different CSV file, you can specify it at runtime
by passing it as the \$FILE environment variable.

Examples:

1) FILE=/home/ubuntu/my_tags.csv $0 ec2 [instance-id] [instance-id] [instance-id]
2) RESOURCES='instance-1-id instance-2-id instance-3-id' API=ec2 $0
3) API=ec2 $0 resources [instance-id] [intance-id] [instance-id]
4) $0 acm [certificate-arn]
"
}

# Show help:
if [[ ($(echo "$1" | grep -i '\-h')) || ($(echo "$1" | grep -i 'help')) ]]; then
  usage
  exit
fi

# Allow passing all resources as arguments if $API is set:
if [[ (-z $(echo "$1" | grep -i 'resource')) || (-z $(echo $1 | grep -i 'arn')) ]]; then
  API="${API:-"$1"}"
fi

# Prompt user if API is not specified:
if [[ -z $API ]]; then
  read -rp 'API Service (lowercase): ' API
  echo
fi

# Prompt user if resources are not specified:
if [[ -z $RESOURCES ]]; then
  read -rp 'ARNs or Resource IDs (separated by space): ' RESOURCES
  echo
fi

apply_tags() {
  # AWS Certificate Manager:
  if [[ $API = 'acm' ]]; then
    aws "$API" add-tags-to-certificate --certificate-arn "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  # EC2:
  elif [[ $API = 'ec2' ]]; then
    aws "$API" create-tags --resources "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  # Other APIs:
  else
    aws "$API" tag-resources --resource-arn-list "$RESOURCES" --tags="${KEY}",Value="${VALUE}"
  fi
}

# Start tagging:
echo "RESOURCES: ${RESOURCES}"

while read line; do
  # Attempt to allow for quoted cell values:
  if [[ -n $(echo "$line" | grep '"') ]]; then
    KEY="$(echo "$line" | awk -F '","' '{print $1}' | tr -d '"')"
    VALUE="$(echo "$line" | awk -F '","' '{print $2}' | tr -d '"')"
  else
    KEY="$(echo "$line" | cut -d',' -f1)"
    VALUE="$(echo "$line" | cut -d',' -f2)"
  fi
  apply_tags
  echo "${KEY}: ${VALUE}"
done < "$FILE"
