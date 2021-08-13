# Lab: Variable Validation and Suppression

Duration: 15 minutes

We may want to validate and possibly suppress and sensitive information defined within our variables.

- Task 1: Valdiate variables in a configuration block
- Task 2: More Validation Options
- Task 3: Suppress sensitive information

## Task 1: Valdiate variables in a configuration block

Add three variables at the top of your configuration file:

```hcl
variable "protein" {
  type = string

  validation {
      condition = contains(["chicken","beef","tofu"],lower(var.protein))
      error_message = "The protein must be in the approved list of proteins."
  }

  validation {
      condition = lower(var.protein) == var.protein
      error_message = "The protein name must not have capital letters."
  }
}
```

## Task 3: More Validation Options

`main.tf`

```hcl
variable "no_caps" {
    type = string

    validation {
        condition = lower(var.no_caps) == var.no_caps
        error_message = "Value must be in all lower case."
    }

}

variable "always_wrong" {
    type = string

    validation {
        condition = length(var.always_wrong) == length(var.always_wrong)
        error_message = "You'll never get this right."
    }
}


variable "ip_address" {
    type = string

    validation {
        condition = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
        error_message = "Must be an IP address of the form X.X.X.X."
    }
}


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
terraform13 apply -var no_caps=morethanthree

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

#output "phone_number" {
#  value = var.phone_number
#}
```