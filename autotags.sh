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

Verified supported APIs:
acm
cloudfront
ec2
elb
elbv2
s3api
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
    aws acm add-tags-to-certificate --certificate-arn "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  # EC2:
  elif [[ $API = 'ec2' ]]; then
    aws ec2 create-tags --resources "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  # ELB:
  elif [[ $API = 'elb' ]]; then
  # ELBv2:
    aws elb add-tags --load-balancer-names "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  elif [[ $API = 'elbv2' ]]; then
    aws elbv2 add-tags --resource-arns "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  # Other APIs:
  else
    aws "$API" tag-resources --resource-arn-list "$RESOURCES" --tags="${KEY}",Value="${VALUE}"
    #aws resourcegroupstaggingapi tag-resources --resource-arn-list "$RESOURCES" --tags Key="${KEY}",Value="${VALUE}"
  fi
}

# Start tagging:
echo "RESOURCES: ${RESOURCES}"

# CLOUDFRONT AND S3:
if [[ ($API = 's3') || ($API = 's3api') || ($API = 'cloudfront') ]]; then
  if ! command -v mlr >/dev/null; then
    echo 'miller package is required for s3 tagging.'
    echo 'please install miller before proceeding.'
    exit 1
  fi
  if ! command -v jq >/dev/null; then
    echo 'jq package is required for s3 tagging.'
    echo 'please install jq before proceeding.'
    exit 1
  fi
  json="tags.json"
  echo '{' > "$json"
  if [[ $API = 'cloudfront' ]]; then
    echo '   "Items": [' >> "$json"
  else
    echo '   "TagSet": [' >> "$json"
  fi
  mlr --c2j cat "$FILE" | sed -e "s/\", \"/\",\\n\"/g;s/{/{\n/;s/}/\n}/" | awk '{$1=$1}1' | sed 's/{/     {/g;s/"Key/       "Key/g;s/"Value/       "Value/g;s/}/     },/g' >> "$json"
  head -n -1 "$json" > tmp && mv tmp "$json"
  echo '     }' >> "$json"
  echo '   ]' >> "$json"
  echo '}' >> "$json"
  jq '(..|select(type == "number")) |= tostring' "$json" > tmp && mv tmp "$json"
  if [[ $API = 'cloudfront' ]]; then
    aws cloudfront tag-resource --resource "$RESOURCES" --tags file://$json
  elif [[ ($API = 's3') || ($API = 's3api') ]]; then
    aws s3api put-bucket-tagging --bucket "$RESOURCES" --tagging file://$json
  fi
  rm -f "$json"
# EVERYTHING ELSE:
else
  awk 'NR>1' "$FILE" | while read line; do
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
  done
fi
