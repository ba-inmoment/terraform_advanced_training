# Lab 13: Import

We've already seen many benefits of using Terraform to build out our cloud infrastructure.
But what if there are existing resources that we'd also like to manage with Terraform?

Enter `terraform import`.

With minimal coding and effort, we can add our resources to our configuration and bring them into state.

## Prepare for Import

A valid authentication method is required for this lab.
If you are working from an EC2 instance with an elevated instance profile, you can use that.
Otherwise, setup your AWS cli.

In order to start the import, our `main.tf` requires a provider configuration.
Start off with a provider block with a region.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

You must also have a destination resource to store state against.
Add an empty resource block now.
We will add an EC2 instance called "linux".

```hcl
resource "aws_instance" "linux" {}
```

We're now all set to import our instance into state!

## Import the Resource

Using the instance ID provided by your instructor, run the `terraform import` command now.
The import command is comprised of four parts.
Example:

- `terraform` to call our binary
- `import` to specify the action to take
- `aws_instance.linux` to specify the resource in our config file (`main.tf`) that this resource corresponds to
- `i-06c07739b65a714c0` to specify the real-world resource (in this case, an AWS EC2 instance) to import into state

> **Note**: The resource name and unique identifier of that resource are unique to each configuration.

See what happens below when we've successfully run `terraform import <resource.name> <unique_identifier>`.

```text
terraform import aws_instance.linux i-06c07739b65a714c0
aws_instance.linux: Importing from ID "i-06c07739b65a714c0"...
aws_instance.linux: Import prepared!
  Prepared aws_instance for import
aws_instance.linux: Refreshing state... [id=i-06c07739b65a714c0]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

Great!
Our resource now exists in our state.
But what happens if we were to run a plan against our current config?

```text
terraform plan
 
  Error: Missing required argument
  
    on main.tf line 5, in resource "aws_instance" "linux":
     5: resource "aws_instance" "linux" {
  
  The argument "ami" is required, but no definition was found.
 
 
  Error: Missing required argument
  
    on main.tf line 5, in resource "aws_instance" "linux":
     5: resource "aws_instance" "linux" {
  
  The argument "instance_type" is required, but no definition was found.
```

We're missing some required attributes.
How can we find those without looking at the console?
Think back to our work with the workspace state.
What commands will show us the information we need?

```bash
terraform state list
aws_instance.linux
```

We now know the exact resource to look for in our state.

```text
terraform state show aws_instance.linux
# aws_instance.linux:
resource "aws_instance" "linux" {
    ami                                  = "ami-09e67e426f25ce0d7"
    arn                                  = "arn:aws:ec2:us-east-1:994408970114:instance/i-06c07739b65a714c0
...
```

Using the output from the above command, we can now piece together the minimum required attributes for our configuration.
Add the required attributes to your resource block and rerun the apply.

```hcl
resource "aws_instance" "linux" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
}
```

```text
terraform plan
...
aws_instance.linux: Refreshing state... [id=i-06c07739b65a714c0]

No changes. Infrastructure is up-to-date.
```

You've successfully imported **and** declared your existing resource into your Terraform configuration.