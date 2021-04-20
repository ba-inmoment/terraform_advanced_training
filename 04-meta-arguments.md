# Lab: Meta-Arguments

Duration: 10 minutes

So far, we've already used arguments to configure your resources. These arguments are used by the provider to specify things like the AMI to use, and the type of instance to provision. Terraform also supports a number of _Meta-Arguments_, which changes the way Terraform configures the resources. For instance, it's not uncommon to provision multiple copies of the same resource. We can do that with the _count_ argument.

- Task 1: Change the number of AWS instances with `count`
- Task 2: Modify the rest of the configuration to support multiple instances
- Task 3: Add variable interpolation to the Name tag to count the new instance

## Task 1: Change the number of AWS instances with `count`

### Step 1.1.1

Add a count argument to the AWS instance in `server/server.tf` with a value of 2:

```hcl
# ...
resource "aws_instance" "web" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu_16_04.image_id
  instance_type          = "t2.micro"
# ... leave the rest of the resource block unchanged...
}
```

## Task 2: Modify the rest of the configuration to support multiple instances

### Step 1.2.1

If you run `terraform apply` now, you'll get an error. Since we added _count_ to the aws_instance.web resource, it now refers to multiple resources. Because of this, values like `aws_instance.web.public_ip` no longer refer to the public_ip of a single resource. We need to tell terraform which resource we're referring to.

To do so, modify the output blocks in `server/server.tf` as follows:

```
output "public_ip" {
  value = aws_instance.web.*.public_ip
}

output "public_dns" {
  value = aws_instance.web.*.public_dns
}
```

The syntax `aws_instance.web.*` refers to all of the instances, so this will output a list of all of the public IPs and public DNS records. 

### Step 1.2.2

Run `terraform apply` to add the new instance. You should see two IP addresses and two DNS addresses in the outputs.

```bash
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

public_dns = [
  "ec2-3-80-192-173.compute-1.amazonaws.com",
  "ec2-54-82-222-24.compute-1.amazonaws.com",
]
public_ip = [
  "3.80.192.173",
  "54.82.222.24",
]
```

You should also run a `terraform state list` to highlight how these items are stored in state when using the `count` argument.

```bash
terraform state list

module.keypair.aws_key_pair.generated
module.keypair.local_file.private_key_pem[0]
module.keypair.local_file.public_key_openssh[0]
module.keypair.null_resource.chmod[0]
module.keypair.tls_private_key.generated
module.server.data.aws_ami.ubuntu_16_04
module.server.aws_instance.web[0]
module.server.aws_instance.web[1]
```

## Task 3: Add variable interpolation to the Name tag to count the new instances

### Step 1.3.1

Interpolate the count variable by changing the Name tag to include the current
count over the total count. Update `server/server.tf` to add a new variable
definition, and use it:

```hcl
# ...
variable private_key {}
variable num_webs {
  default = "2"
}

resource "aws_instance" "web" {
  count                  = var.num_webs
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = var.key_name

  tags = {
    "Identity"    = var.identity
    "Name"        = "Student ${count.index + 1}/${var.num_webs}"
    "Environment" = "Training"
  }

# ...
```

The solution builds on our previous discussion of variables. We must create a
variable to hold our count so that we can reference that count twice in our
resource. Next, we replace the value of the count parameter with the variable
interpolation. Finally, we interpolate the current count (+ 1 because it's
zero-indexed) and the variable itself.

### Step 1.3.2

Run `terraform apply` in the terraform directory. You should see the revised tags that count the instances in the apply log.

```shell
terraform apply
```

### Counts on Modules
The Terraform 0.13 release added many new features and now extends the use of some meta-arguments to the use of modules directly.  For example we can now place the `count` argument on the module itself.

Update your `main.tf` to use a count on the module resource block.

```hcl
module "server" {
  source                 = "./server"
  count                  = 2
  # ami                  = "ami-09943f9da1f1b7899"
  subnet_idd             = "subnet-09b6aa2dec2bfc70a"
  vpc_security_group_ids = ["sg-0e9749a0ce2d20bb3"]
  identity               = "terraform-nyl-ant"
  key_name               = module.keypair.key_name
  private_key            = module.keypair.private_key_pem
}
```
and update the `output` resource blocks to account for the change:

```hcl
output "public_ip" {
  value = module.server.*.public_ip
}

output "public_dns" {
  value = module.server.*.public_dns
}
```

Run a `terraform validate` to validate syntax along with a `terraform plan` to highlight the impact of this change.

```bash
terraform plan

...
Plan: 4 to add, 0 to change, 2 to destroy.

```

You will notice that the plan indicates that it will destroy our two existing servers, which may come as a surprise.  This is a direct result of using the `count` meta-argument and could become an issue.

The reason for the destroy can be showcased by using a  `terraform state list` to show how the items are referenced within state both before and after specifiying the `count` paramaeter on the module.

Before:
```bash
terraform state list

module.keypair.aws_key_pair.generated
module.keypair.local_file.private_key_pem[0]
module.keypair.local_file.public_key_openssh[0]
module.keypair.null_resource.chmod[0]
module.keypair.tls_private_key.generated
module.server.data.aws_ami.ubuntu_16_04
module.server.aws_instance.web[0]
module.server.aws_instance.web[1]
```

Let's now run a `terraform apply` to build out our multiple modules, and showcase the results of a `terraform state list` afterwards for comparison.

```bash
Apply complete! Resources: 4 added, 0 changed, 2 destroyed.

Outputs:

public_dns = [
  [
    "ec2-3-89-6-38.compute-1.amazonaws.com",
    "ec2-34-235-120-118.compute-1.amazonaws.com",
  ],
  [
    "ec2-18-234-123-101.compute-1.amazonaws.com",
    "ec2-18-232-106-115.compute-1.amazonaws.com",
  ],
]
public_ip = [
  [
    "3.89.6.38",
    "34.235.120.118",
  ],
  [
    "18.234.123.101",
    "18.232.106.115",
  ],
]
```

After:
```bash
terraform state list

module.keypair.aws_key_pair.generated
module.keypair.local_file.private_key_pem[0]
module.keypair.local_file.public_key_openssh[0]
module.keypair.null_resource.chmod[0]
module.keypair.tls_private_key.generated
module.server[0].data.aws_ami.ubuntu_16_04
module.server[0].aws_instance.web[0]
module.server[0].aws_instance.web[1]
module.server[1].data.aws_ami.ubuntu_16_04
module.server[1].aws_instance.web[0]
module.server[1].aws_instance.web[1]
```

You will see that the count argument has indexed reference in the state file.