# Lab: Local Variables

Duration: 15 minutes

A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it.  The expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values.

- Task 1: Create local variables in a configuration block
- Task 2: Interpolate local variables
- Task 3: Using locals with variable expressions
- Task 4: Using locals with terraform expressions and operators

## Task 1: Create local variables in a configuration block

Add local variables to your `server.tf` module configuration file:

```hcl
locals {
  service_name = "Automation"
  owner        = "Cloud Team"
}
```

## Task 2: Interpolate local variables into your existing code

Update the `aws_instance` block inside your `server.tf` to add new tags to all instances using local variable interpolation.

```hcl
...

tags = {
    "Identity"    = var.identity
    "Name"        = "Student"
    "Environment" = "Training"
    "Service"     = local.service_name
    "Owner"       = local.owner 
  }

...
```

After making these changes, rerun `terraform plan`. You should see that there will be some tagging updates to your server instances.  Execute a `terraform apply` to make these changes.

## Task 3: Using locals with variable expressions

Expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values.

Add another local variable block to your `server.tf` module configuration which references the local variables set in the previous portion of the lab.

```hcl
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Identity    = var.identity
    Name        = "Student"
    Environment = "Training"
    Service = local.service_name
    Owner   = local.owner
  }
}
```

Update the `aws_instance` tags block inside your `server.tf` to reference the `local.common_tags` variable.

```hcl
resource "aws_instance" "web" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = local.common_tags
}
```

After making these changes, rerun `terraform plan`. You should see that there are no changes to apply, which is correct, since the variables contain the same values we had previously hard-coded, but now that are 

```text
...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

## Task 4: Using locals with terraform expressions and operators
Locals are commonly used to transform or combine values using expressions supported within HCL.  This can help make the code based within a given resource block easier to read.

Add the following locals block to your `server.tf` module, which utilizes a terraform conditional operator to determine the image id for a given server.  This allows a consumer of the module to specify their own AMI or to have terraform select the appropriate AMI based on server operating system.  This logic is handled within the terraform local variable and then reference within the `aws_instance` resource block.

Create a `data.tf` file within your server module directory if it doesn't already exist with the following code:

`data.tf`

```hcl
data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["801119661308"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

data "aws_ami" "ubuntu_18" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}
```

Add the following code to your `server.tf` file to define the `server_os` variable and local ami.

`server.tf`

```hcl
variable "ami" {
  description = "amazon server image"
  default = ""
}

variable "server_os" {
  type        = string
  description = "Server Operating System"
  default     = "ubuntu"
}

locals {
  server_os = {
    "ubuntu" = data.aws_ami.ubuntu.image_id
    "windows" = data.aws_ami.windows.image_id
    "ubuntu_18" = data.aws_ami.ubuntu_18.image_id
  }

  ami = (var.ami != "" ? var.ami : lookup(local.server_os, var.server_os))

}
```

Update the `aws_instance` resource block within your `server.tf` to call the `local.ami` value.

`server.tf`

```hcl
...

resource "aws_instance" "web" {
  count                  = var.num_webs
  ami                    = local.ami
  instance_type          = "t2.micro"

...
```

After making these changes, rerun `terraform plan`. You should see that there are no changes to apply since the code is using the user specified ami.

```text
...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```


Update the root module to specify a `server_os` rather then a specific `ami`

`main.tf`

```hcl
module "server" {
  source                 = "./server"
  ami                    = ""
  server_os              = "ubuntu_18"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  identity               = var.identity
  key_name               = module.keypair.key_name
  private_key            = module.keypair.private_key_pem
}
```

After making these changes, rerun `terraform plan`. You should see that the servers will be replaced with the new server operating system that is specified.

Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration, but if overused they can also make a configuration hard to read by future maintainers by hiding the actual values used.

Use local values only in moderation, in situations where a single value or result is used in many places and that value is likely to be changed in future. The ability to easily change the value in a central place is the key advantage of local values.
