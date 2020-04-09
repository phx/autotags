#!/bin/bash

set -e

FILE="${FILE:-"tags.csv"}"
API="${API:-"$1"}"
RESOURCES="${RESOURCES:-"${@:2}"}"

if [[ -z $API ]]; then
  read -rp 'API Service (lowercase): ' API
  echo
fi
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

# SCRIPT START:

echo "RESOURCES: ${RESOURCES}"

while read line; do
  KEY="$(echo "$line" | cut -d',' -f1)"
  VALUE="$(echo "$line" | cut -d',' -f2)"
  apply_tags
done < "$FILE"
