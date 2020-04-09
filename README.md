# AWS Auto Tags

This is a simple script I created in order to simplify the tagging of AWS resources.
There isn't a global top-level command for tagging in `awscli` since each service uses their own API.
This means some commands to create tags are a bit different.

This script is extremely simple and is by no means full-featured or even complete.
I'm just updating it as I go along.
I'm using it for work, but there is nothing organization-specific about it, so I figured I would share it in case others could benefit from it or wanted to contribute.

---

## Usage

Script variables can be passed in as both command line parameters, as well as environment variables.

**It's only looking for 3 things:**
- `$API` (or first argument)
- `$RESOURCES` (or second argument)
- `$FILE` (or a file in the same directory named `tags.csv`)

### Example with command line arguments

`./autotags.sh ec2 instance-1-id instance-2-id instance-3-id`

This will apply the key/value pairs listed in `tags.csv` to the 3 instances passed on the command line.

### Example with environment variables

`FILE='/home/ubuntu/Downloads/my_spreadsheet.csv' API=ec2 RESOURCES='instance-1-id instance-2-id instance-3-id' ./autotags.sh`

This will apply the key/value pairs listed in `/home/ubuntu/Downloads/my_spreadsheet.csv` to the 3 EC2 instances that are separated by spaces in the `$RESOURCES` variable.

### Other information

`awscli` supports multiple resources in their API calls, and I believe in some cases can support up to 1,000 resource IDs or ARNs.

Since their APIs are optimized for this, if you need to tag 1,000 EC2 instances, it would be much quicker to get a list of those instances and pass them all at once, rather than making a separate API call to tag
each instance.  See examples below.

** Rather than doing this: **

```sh
for i in $(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text); do
  ./autotags.sh ec2 "$i"
done
```

** It would probably be more efficient to do this: **

`RESOURCES="$(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text | tr "\n" " ")" ./autotags.sh ec2`
