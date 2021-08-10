# Lab 5: Refactoring Terraform Code Layout

Duration: 15 minutes

As you get more comfortable provisioning infrastructure with Terraform, we will want to begin thinking about what this code might look like once it's in production.  Resource blocks will grow to include variables, outputs, state sourcing, and various other components that will introduce a level of complexity to our code.  This may become untenable as our Terraform files grow to include multiple modules and different types of resources.  In order to keep our code clean, it is best to begin thinking about ways that we can break out like code blocks into their own files so that we our workspace only contains the minimum amount of relevant information.  This will help keep our workspace clean while also only presenting us with relevant bits of information in their relevant sections.

## Important to know
- Terraform concatenates all of the `.tf` files together at runtime, regardless of how many are in the run directory.  
- As we've discussed, Terraform is non-recursive.  It will only concatenate files in the run directory.
- Terraform must be given unique indentifiers for every resource to be provisioned, e.g. you can only have one `aws_instance.web`.
- With all of this in mind, be mindful of how you name extraneous files in your run directory.  You do not want to call backup files something along the lines of `backup.tf`, as Terraform will see this as a valid configuration file and look to include it during the concatenation phase of the `plan` or `apply`. 
- If you wish to store backup files in your run directory, it would be more appropriate to name them `file.tf.bak` or something along those lines.  Just do not end the file in `.tf`.


## Tasks
- Task 1: Break out our variables and outputs into their own files and successfully run a Terraform plan.
- Task 2. Successfully run a terraform plan and debug code where necessary

## Task 1: Break out the variables and outputs into their own files and successfully run a Terraform plan.

### Step 5.1.1

Create a new files for both outputs and variables in the same directory as your `main.tf`

```shell
touch outputs.tf
touch variables.tf
```

### Step 5.1.2

Copy the variables from the `main.tf` file and place them into the new `variables.tf` file.  Remove the variables block from your `main.tf`.
```hcl
#contents of the variables.tf file
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-1"
}
variable "ami" {}
variable "subnet_id" {}
variable "identity" {}
variable "vpc_security_group_ids" {
  type = list(any)
}
```

### Step 5.1.3

Copy the outputs from the `main.tf` file and place them into the new `outputs.tf` file.  Remove the outputs block from your main.tf.

```hcl
#contents of the outputs.tf file
output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}
```

## Task 2: Successfully run a terraform plan and debug code where necessary

### Step 5.2.1
Review the contents of your `main.tf`.  At this point, it should only include your provider info and your resource block(s):

```hcl
#contents of your main.tf
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = "t2.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = {
    "Identity"    = var.identity
    "Name"        = "Student"
    "Environment" = "Training"
  }
}
```


### Step 5.2.2
Run `terraform plan`.  If your infrastructure is already provisioned and your code was refactored correctly, you should see no changes to your existing infrastructure with this step:

```shell
terraform plan
aws_instance.web: Refreshing state... [id=i-123456789abc]

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your configuration and the remote system(s). As a result, there are no actions to take.
```

## Conclusion
While the concepts in this lab are relatively straightforward, the concept of file modularity is a core component of Terraform.  We will be exploring this concept in much greater depth in future labs.  However, it is important to begin conceptualizing like code blocks as their own files as early in the process as possible.  As your Terraform code grows and becomes more complex (and used by other teams), segregating your code based on variables/outputs/values/etc will allow it to be more easily readable by others (and yourself as your code starts to balloon).  Terraform code itself is often a game of connect the dots, where the dots are represented by variables, outputs, resources, and modules that live in different levels of the file hierarchy.  Code segregation allows this concept to be more easily traceable.
