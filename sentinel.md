# Lab: Sentinel Policy-as-Code
Sentinel is the Policy-as-Code product from HashiCorp that automatically enforces logic-based policy decisions across all HashiCorp Enterprise products.

It allows users to implement policy-as-code in a similar way to how Terraform implements infrastructure-as-code. The Sentinel Command Line Interface (CLI) allows you to apply and test Sentinel policies, including those that use mocks generated from Terraform Cloud and Terraform Enterprise plans.

- Task 1: Setup Workspace in Terraform Cloud
- Task 2: Download Sentinel CLI
- Task 3: Create Sentinel Policy
- Task 4: Testing Sentinel Policy
- Task 5: Enforce Sentinel Policy

## Task 1: Setup Workspace in Terraform Cloud 
You should already have a Terraform Cloud account with Team and Governance capabilities, if it has been less 30 days since you activated the trial on your Terraform Cloud account you are good to go. If you do not have a Terraform Cloud account already, please create an account

Once you have created an account, run the terraform login command and open the link in the output to create and store credentials for the terraform CLI. The credentials allow the CLI to communicate with your organization in Terraform Cloud.

```bash
terraform login
```

Create a new directory called `sentinel-test` that contains a `main.tf` with the following code:

```hcl
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "<ORGANIZATION>"
    workspaces {
      name = "sentinel-test-ws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "petname" {
  length    = 4
  separator = "-"
}

resource "aws_s3_bucket" "dev" {
  bucket = "sentinel-ws-${random_pet.petname.id}"
  acl    = "public-read"
  force_destroy = true

  tags = {
    environment = "dev"
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::sentinel-ws-${random_pet.petname.id}/*"
            ]
        }
    ]
}
EOF
}
```

Set credentials for the AWS provider in your workspace.

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

```bash
cd sentinel-test
terraform init
terraform apply
```

## Task 2: Download Sentinel CLI

The Sentinel CLI is a command-line interface for local development and testing. For the getting started guide, we'll use the CLI to learn how to write policies for Sentinel-enabled applications. The Sentinel CLI is distributed as a binary package for all supported platforms and architectures.

```bash
curl -sfLo sentinel.zip https://releases.hashicorp.com/sentinel/0.18.4/sentinel_0.18.4_linux_amd64.zip
unzip -qq sentinel.zip 
which sentinel
sudo mv sentinel /usr/local/bin/sentinel
sentinel version
```

## Task 3: Create Sentinel Policy
Now that we have a working Terraform configuration and workspace, lets create a policy to set guardrails around one of type of resources created by our config. We want to enforce 2 organization requirements for S3 buckets:

- All S3 buckets should have department and environment tags
- All S3 bucket should use the private ACL to prevent accidental data leaks

Create a new directory called `sentinel-policies` that contains a `restrict-s3-buckets.sentinel` with the following code:

`restrict-s3-buckets.sentinel`
```ruby
# A sentinel policy for S3 buckets that enforces required tags are provided
# and bucket acl is set to private

import "tfplan/v2" as tfplan

# Filter S3 buckets


# Rule to require "department" and "environment" tags


# Rule to require "private" ACL on all buckets


# Main rule that requires other rules to be true
```

A Sentinel policy can include imports which enable a policy to access reusable libraries, external data and functions. Terraform Cloud provides four built-in imports that can be used for a policy check:

__tfplan__ provides access to Terraform plan details which represent the changes Terraform will make to reach desired state
__tfconfig__ provides access to Terraform configuration that is being used to describe the desired states
__tfstate__ provides access to Terraform state, which represents what Terraform knows about the real world resources
__tfrun__ provides access to information about a run

_Note:_ Some imports can have a v2 suffix which indicates they represent the new data structures used post Terraform 0.12

An import for __tfplan__ has already been configured in the stub policy. Let's create a filter expression to isolate the resources this policy applies to: S3 buckets. Add the filter block below to the stub policy file at `restrict-s3-buckets.sentinel`

```ruby
s3_buckets = filter tfplan.resource_changes as address, rc {
  rc.type is "aws_s3_bucket" and
  (rc.change.actions contains "create" or rc.change.actions is ["update"])
}
```

Here is what is happening:

- __tfplan__ is a frequently used import in policies since it provides details about planned changes. Later in this lab we will go over how you can determine what information is available to your policy from the import.
- __tfplan.resource_changes__ is a collection with the resource address as the key and a resource change object as the value.
- We are iterating over each of the resource change objects in the collection and using the filter function to filter out change objects whose type is aws_s3_bucket.
- The type name matches the resource block we would define in a .tf file to manage S3 buckets.

A policy can be broken down into a set of rules. Breaking down a policy into rules can make it more understandable and aids with testing. Lets create our first rule which enforces that required tags are provided. Add the following block under the commented line # Rule to require "department" and "environment" tags

```ruby
required_tags = ["department", "environment"]
tag_violators = filter s3_buckets as address, bucket {
  any required_tags as rtag {
    rtag not in bucket.change.after.tags
  }
}

bucket_should_have_required_tags = rule {
  tag_violators is empty
}
```

In this rule we are using an any expression to test if any of the required tags are not present in the bucket's list of tags after changes are applied. If a tag is found to be missing, the expression evaluates to true and the resource is added to the violators list.

The rule expects the violators list to be empty. If the list is not empty it indicates violators were found and the rule expression evaluates to false.

Our Terraform config could have contained any number of resources including multiple S3 buckets. The first filter expression gets us all s3_buckets, the second filter expression filters out all buckets that are in violation of our rule.

Let's add our second rule to enforce a private ACL on our buckets. Once again we will use a filter expression, this time selecting resources where our required value is not used.

```ruby
acl_violators = filter s3_buckets as address, bucket {
  bucket.change.after.acl != "private"
}
bucket_acl_should_be_private = rule {
  acl_violators is empty
}
```

Each Sentinel policy is expected to contain a main rule. The result of the policy depends on the evaluated contents of the main rule. For booleans, a policy passes on a true value, and fails on a false value.

Let's add a main rule, the result of which is the combination of the 2 rules we have defined earlier.

```ruby
main = rule { bucket_should_have_required_tags and bucket_acl_should_be_private else false }
```

We are doing a logical AND with our 2 rules. If either one of our rules evaluates to false, our main rule evaluates to false and our policy check fails.

That's it, our first policy is ready! Below is the complete policy.
`restrict-s3-buckets.sentinel`

```ruby
# A sentinel policy for S3 buckets that enforces required tags are provided
# and bucket acl is set to private

import "tfplan/v2" as tfplan

# Filter S3 buckets
s3_buckets = filter tfplan.resource_changes as address, rc {
  rc.type is "aws_s3_bucket" and
  (rc.change.actions contains "create" or rc.change.actions is ["update"])
}

# Rule to require "department" and "environment" tags
required_tags = ["department", "environment"]
tag_violators = filter s3_buckets as address, bucket {
  any required_tags as rtag {
    rtag not in bucket.change.after.tags
  }
}

bucket_should_have_required_tags = rule {
  tag_violators is empty
}

# Rule to require "private" ACL on all buckets
acl_violators = filter s3_buckets as address, bucket {
  bucket.change.after.acl != "private"
}
bucket_acl_should_be_private = rule {
  acl_violators is empty
}

# Main rule that requires other rules to be true
main = rule { bucket_should_have_required_tags and bucket_acl_should_be_private else false }
```

```bash
sentinel fmt restrict-s3-buckets.sentinel
```

## Task 4: Testing Sentinel Policy

The Sentinel CLI allows for the development and testing of policies outside of TFC/TFE. Sentinel Mocks are imports used to mock the data available to the Sentinel engine when running after a plan in TFE/TFC.

Sentinel imports are structured as a series of collections with a number of attributes. The structure of each standard import is clearly documented.

Due to the highly variable structure of data that can be produced by an individual Terraform configuration, Terraform Cloud and Enterprise provide the ability to generate mock data from existing configurations. This can be used to create sample data for testing new policies, or data to reproduce issues in an existing one.

Mock data can be easily generated using the Terraform Cloud UI or the API after a plan has executed.

Download the Mocks

Take a moment to explore them by opening the `workspace/sentinel/mocks` folder.

Can you find the resource_changes attribute from the mock file that would supply the tfplan/v2 import? If yes, can you tell what the S3 bucket's ACL will be after the update?

For Sentinel to use to use mocks, the CLI must be provided with a configuration file. This can be specified using the -config=path flag. 

Create a sentinel-mocks.hcl file with the following code at `sentinel/sentinel-mocks.hcl`

`sentinel-mocks.hcl`
```hcl
mock "tfconfig" {
  module {
    source = "mocks/mock-tfconfig.sentinel"
  }
}

mock "tfconfig/v1" {
  module {
    source = "mocks/mock-tfconfig.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mocks/mock-tfconfig-v2.sentinel"
  }
}

mock "tfplan" {
  module {
    source = "mocks/mock-tfplan.sentinel"
  }
}

mock "tfplan/v1" {
  module {
    source = "mocks/mock-tfplan.sentinel"
  }
}

mock "tfplan/v2" {
  module {
    source = "mocks/mock-tfplan-v2.sentinel"
  }
}

mock "tfstate" {
  module {
    source = "mocks/mock-tfstate.sentinel"
  }
}

mock "tfstate/v1" {
  module {
    source = "mocks/mock-tfstate.sentinel"
  }
}

mock "tfstate/v2" {
  module {
    source = "mocks/mock-tfstate-v2.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "mocks/mock-tfrun.sentinel"
  }
}
```

```bash
cd /root/workspace/sentinel
sentinel apply -config=sentinel-mocks.hcl restrict-s3-buckets.sentinel
```

You should see a failure message indicating the main rule failed as well as the nested rule that resulted in the failure.

Note: Sentinel uses lazy evaluation, since the first rule evaluated to false, the 2nd one was not evaluated fully because Sentinel knows the policy has already failed.

Let's add some logging to our policy so it becomes clearer what is causing the failures. Open the policy file, restrict-s3-buckets.sentinel, in the Code Editor tab and add the following block right before the main rule

```ruby
# Before the main rule!
for tag_violators as name, bucket {
  print(bucket.address, "tags:", keys(bucket.change.after.tags), "\n\trequired tags:", required_tags,"\n")
}

for acl_violators as name, bucket {
  print(bucket.address, "acl:", bucket.change.after.acl, "\n\trequired acl:", "private","\n")
}
```

Run sentinel apply with the correct params once again, this time you should see our custom message. The print function can output any sentinel value (including arbitrary strings) and can be useful for debugging.

While running apply is helpful to validate a policy, Sentinel comes with a built-in test framework to validate a policy behaves as expected for a number of cases.

Sentinel is opinionated about the folder structure required for tests. This opinionated structure allows testing to be as simple as running sentinel test with no arguments. Additionally, it becomes simple to test with a CI system or add new policies.The structure Sentinel expects is test/<policy>/<test_name>.[hcl|json] where <policy> is the name of your policy file without the file extension.

Within that folder should be a list of HCL or JSON files. Each file represents a single test case.

As part of lab setup, 2 test cases were created for you. Take a look at them in /root/workspace/sentinel/test using the Code Editor.

The tests define:

Sentinel imports that are mocked and the source of these mocked values.
Tests for rules in the policy and their expected result.
For the fail scenario we expect policy to fail, thus the main rule should evaluate to false. Vice versa for the pass scenario, the main rule should evaluate to true

We already have the data for the failure scenario from our mock export, we need to create the mock data used by the pass scenario. To do this we will copy the existing mock we downloaded from TFC and update the values we are testing for.

Note that the copied mock file's name should correspond with the source we have defined in the test scenario file pass.hcl

```bash
cd /root/workspace/sentinel/mocks/
cp mock-tfplan-v2.sentinel mock-tfplan-v2-pass.sentinel
```

Once copied open mock-tfplan-v2-pass.sentinel in the Code Editor. Make sure you open the file with pass in its name because this is the file we want to modify for our pass scenario.

You will need to make 2 changes in mock-tfplan-v2-pass.sentinel, one for each of our failing rules. Please make sure you update the correct nested attribute!

resource_changes > aws_s3_bucket.dev > change > after > acl, change this value to private
resource_changes > aws_s3_bucket.dev > change > after > tags, add the second required tag department and any value
Run sentinel test in the directory with your sentinel policy to verify your config works! The verbose parameter displays output from print statements which can be useful for debugging.

```bash
cd /root/workspace/sentinel
sentinel test --verbose
```

Sentinel tests can be integrated in CI pipelines to ensure policy updates continue to have the intended effect. When teams discover additional use cases/exceptions, these are added into policies and corresponding test cases created. This allows policy updates to be made with confidence.

## Task 5: Enforce Sentinel Policy

Policies are managed as parts of versioned policy sets, which allow individual policy files to be stored in a supported VCS provider or uploaded via the Terraform Cloud API.

A policy set is simply a directory structure containing a Sentinel configuration file and some policy files. We recommend that these files and configurations be treated like any other code and be checked in to a source control system. Once configured, policy sets can be enforced on all workspaces in an organization or a desired subset.

Every policy set requires a configuration file named sentinel.hcl. This configuration file defines:

Each policy that is part of the set and where to find it
The enforcement level of each policy
Any sentinel modules which need to be made available to policies in the set.
Sentinel modules allow sentinel code to be shared and imported, reducing the amount of boilerplate code required in each policy. We are not using a module in this lab but you can see [examples here](https://github.com/hashicorp/terraform-guides/blob/d5c1a1e8abacc497f99f1ac2fde27e5cf273d24d/governance/third-generation/aws/sentinel.hcl#L2)

We need a sentinel.hcl to configure our policy set. For now we are enforcing only 1 policy and because it can be dangerous to have public buckets we will require hard-mandatory enforcement. Use the Code Editor to update the file at /root/workspace/sentinel/sentinel.hcl with:

```ruby
policy "restrict-s3-buckets" {
  source            = "./restrict-s3-buckets.sentinel"
  enforcement_level = "hard-mandatory"
}
```

The source for a policy defined in a set can be a path relative to the configuration file or a remote HTTP/HTTPS source.


Once a policy set is created it must be configured inside Terraform Cloud. We recommend you connect policy sets using a VCS provider for easy updates. For this lab we will upload a policy set version using the API. Follow the steps below to set this up:

- Navigate to Terraform Cloud in a new tab
- Select the organization you are using for this lab, it must have an active Team and Governance subscription.
- Click Settings, then select Policy sets
- Click Connect a new policy set
- Select No VCS connection since we will be using the API to upload the policy set
- On the Configure settings page provide an indicative name and a description
- Select ** Policies enforced on all workspaces** (default)
- Click Connect policy set

Great - you've created a policy set in Terraform Cloud. To actually use it we will need to upload our Sentinel policies which is a 2 step process

Create a new version of the policy set
Upload the policies for the new version
To do this we will need the Policy Set ID:

Click the newly created policy set
Copy the policy set ID from the URL. It should be a string similar to polset-rUWUq752Y2d5HkAH
Once you have the policy set ID, create a policy set version with the API using the commands below. Be sure to replace the placeholder POLICYSET_ID with the ID from the previous step.

```bash
TFC_TOKEN=$(jq -r '.credentials."app.terraform.io".token' ~/.terraform.d/credentials.tfrc.json)
curl --silent \
  --header "Authorization: Bearer $TFC_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  https://app.terraform.io/api/v2/policy-sets/<POLICYSET_ID>/versions |jq
```

The response will include an upload link. We will use this to upload a policy set version as tarball. The tarball needs to include the sentinel.hcl config file and all .sentinel policy files with a local source.

Run the following commands to create our tarball package and add sentinel.hcl and the policy file.

```bash
cd /root/workspace/sentinel
tar --create --gzip --file=policy-set.tar.gz sentinel.hcl restrict-s3-buckets.sentinel
```

Now we can upload this tarball. Be sure to replace the upload URL with the full upload URL from above. The URL is quite long so make sure you copy all characters otherwise you will get a Bad Request error.

```bash
curl \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @policy-set.tar.gz \
  https://archivist.terraform.io/v1/object/.....
```

Finally! Our policy set is place.

Note that this process is intended to be automated using a CI orchestrator or the VCS integration and should be much faster in practice.

Now that we have a policy set enforcing on all our workspaces, lets test if it actually works. Switch to the tf-config directory and run `terraform apply`

```bash
cd /root/workspace/tf-config
terraform apply
```

Your run should fail once it hits the Organization policy check which is expected.

Congratulations!! You have just created your first sentinel policy and used policy-as-code to prevent non-compliant infrastructure from being created.

If you would like to confirm your policy allows configuration that comply you can fix your terraform config in /root/workspace/tf-config/main.tf and run terraform apply again.