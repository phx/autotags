# AWS Auto Tags

This is a simple script I created in order to simplify the tagging of AWS resources.
There isn't a global top-level command for tagging in `awscli` since each service uses their own API.
This means some commands to create tags are a bit different.

This script is extremely simple and is by no means full-featured or even complete.
I'm just updating it as I go along.
I'm using it for work, but there is nothing organization-specific about it, so I figured I would share it in case others could benefit from it or wanted to contribute.

---

## Usage

```sh

Usage: ./autotags.sh [API] [RESOURCES]

$API and $RESOURCES can also be specified as environment variables.

Note: If $API is specified as an environment variable,
      the first argument must include the word 'resource' or 'arn',
      followed by the resources you wish to tag.

By default, ./autotags.sh looks for 'tags.csv' in the current directory.
If you wish to use a different CSV file, you can specify it at runtime
by passing it as the $FILE environment variable.

Examples:

1) FILE=/home/ubuntu/my_tags.csv ./autotags.sh ec2 [instance-id] [instance-id] [instance-id]
2) RESOURCES='instance-1-id instance-2-id instance-3-id' API=ec2 ./autotags.sh
3) API=ec2 ./autotags.sh resources [instance-id] [intance-id] [instance-id]
4) ./autotags.sh acm [certificate-arn]

Tested APIs:
acm
ec2
elb
elbv2
s3
```

Script variables can be passed in as both command line parameters, as well as environment variables.

**It's only looking for 3 things:**
- `$API` (or first argument)
- `$RESOURCES` (or every argument after `$1` unless `$API` is defined *AND* `resources` or `arns` is passed as `$1`)
- `$FILE` (or a file in the same directory named `tags.csv`)

**Caveats:**
- This script does not work with `.xlsx` or Excel-specific filetypes -- **ONLY CSV!**
- `mlr` (miller) and `jq` are required for tagging S3 resources.

---

### Example one-liner with command line arguments

`./autotags.sh ec2 instance-1-id instance-2-id instance-3-id`

This will apply the key/value pairs listed in `tags.csv` to the 3 instances passed on the command line.

### Example one-liner with environment variables

`FILE='/home/ubuntu/Downloads/my_spreadsheet.csv' API=ec2 RESOURCES='instance-1-id instance-2-id instance-3-id' ./autotags.sh`

This will apply the key/value pairs listed in `/home/ubuntu/Downloads/my_spreadsheet.csv` to the 3 EC2 instances that are separated by spaces in the `$RESOURCES` variable.

Variables *must be passed on the same command line when running the script* unless you `export` them first.

---

### Other information

`awscli` supports multiple resources in API calls, and I believe in some cases can support up to 1,000 resource IDs or ARNs.

Since AWS APIs are optimized for this, if you need to tag 1,000 EC2 instances, it would be much quicker to get a list of those instances and pass them all at once, rather than making a separate API call to tag
each instance.  See examples below.

**Rather than doing this:**

```sh
for i in $(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text); do
  ./autotags.sh ec2 "$i"
done
```

**It would probably be more efficient to do this:**

`RESOURCES="$(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text | tr '\n' ' ')" ./autotags.sh ec2`
