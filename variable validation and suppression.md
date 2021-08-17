# Lab: Variable Validation and Suppression

Duration: 15 minutes

We may want to validate and possibly suppress and sensitive information defined within our variables.

- Task 1: Valdiate variables in a configuration block
- Task 2: More Validation Options
- Task 3: Suppress sensitive information

## Task 1: Valdiate variables in a configuration block

Create a new folder called `variable_validation` with a `variables.tf` configuration file:

```hcl
variable "cloud" {
  type = string

  validation {
    condition     = contains(["aws", "azure", "gcp", "vmware"], lower(var.cloud))
    error_message = "You must use an approved cloud."
  }

  validation {
    condition     = lower(var.cloud) == var.cloud
    error_message = "The cloud name must not have capital letters."
  }
}
```

Perform a `terraform init` and `terraform plan`.  Provide inputs that both meet and do not meet the validation conditions to see the behavior.

```bash
terraform plan -var cloud=aws
terraform plan -var cloud=alibabba
```

## Task 2: More Validation Options

Add the following items to the `variables.tf`

```hcl
variable "no_caps" {
    type = string

    validation {
        condition = lower(var.no_caps) == var.no_caps
        error_message = "Value must be in all lower case."
    }

}

variable "character_limit" {
    type = string

    validation {
        condition = length(var.character_limit) == 3
        error_message = "."
    }
}


variable "ip_address" {
    type = string

    validation {
        condition = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
        error_message = "Must be an IP address of the form X.X.X.X."
    }
}
```

```bash
terraform plan -var cloud=aws -var no_caps -var ip_address=1.1.1.1 -var character_limit=gabe

terraform plan -var cloud=all -var "no_caps=Gabe" -var "ip_address=1223.22.342.22" -var "character_limit=ga"
```

```hcl
module "default_variable" {
    source = "./my_module"
    my_str = var.no_caps
    
}

output "ip_address" {
    value = var.ip_address
}

output "no_caps" {
    value = var.no_caps
}
```

Create a directory for a module `my_module` with a `main.tf` inside:


`/my_module/main.tf`

```hcl
variable "my_str" {
    type = string

    validation {
        condition = length(var.my_str) > 3
        error_message = "String must be over 3 characters in length."
    }
    default = "my-string"
}

output "my_str" {
    value = var.my_str
}
```

terraform init

#There will be errors
terraform apply 

# Comment out the always wrong

# Try with bad values

terraform apply -var no_caps=ALL_CAPS

terraform apply -var ip_address=10.1.1.

# Uncomment module
terraform apply -var no_caps=morethanthree

## Task 3: Suppress sensitive information

Mark variables as sensitive and suppress that information

```hcl
variable "protein" {
    type = string
    default = "chicken"
}

variable "cheese" {
  type = string
  default = "cheddar"
  description = "Type of cheese to put on the taco."
}

variable "toppings" {
  type = list
  default = ["lettuce","tomato","jalapenos"]
}

variable "phone_number" {
  type = string
  sensitive = true
  default = "867-5309"
}

locals {
  my_taco = {
      protein = var.protein
      cheese = var.cheese
      toppings = var.toppings
      phone_number = var.phone_number
  }

  my_number = nonsensitive(var.phone_number)
}

output "phone_number" {
  value = var.phone_number
}
```