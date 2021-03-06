# Lab 15: Migrate Variables to Terraform Enterprise

Duration: 15 minutes

This lab demonstrates how to store variables to Terraform Enterprise.

- Task 1: Update Terraform Code to use variables and store them within Terraform Cloud
- Task 2: Validate Variable Migration was successful
  
## Prerequisites

For this lab, we'll assume that you've installed [Terraform](https://www.terraform.io/downloads.html) and that you have [signed up](https://app.terraform.io/signup/account) for a Terraform Cloud account and have completed the `remote-state` and `read-state` labs.

## Task 1: Update Terraform Code to use variables and store them within Terraform Cloud

Now that we have our state stored in Terraform Cloud in our `server` workspace, we will take the next logical step and store our sensitive variables into TFC as well.


### Step 15.1.1

Set and define your variable values in the Variables section of the `server` workspace of Terraform Cloud.

Rename your `terraform.auto.tfvars` to `terraform.tfvars`

Next reinitialize your terraform project locally and run a `terraform plan` to validate that refactoring your code to make use of variables within TFC did not introduce any planned infrastructure changes.  This can be confirmed by validating a zero change plan.

```bash
terraform plan

Running plan in the remote backend. Output will stream here. Pressing Ctrl-C
will stop streaming the logs, but will not stop the plan running remotely.

Preparing the remote plan...

To view this run in a browser, visit:
https://app.terraform.io/app/Enterprise-Cloud/server-build/runs/run-DGXauYrWeB1xwwPx

Waiting for the plan to start...

Terraform v1.0.4
Configuring remote state backend...
Initializing Terraform configuration...
module.keypair.tls_private_key.generated: Refreshing state... [id=34a0559a16dc68108d30a76d9a5a7b25f8885e1e]
module.keypair.local_file.public_key_openssh[0]: Refreshing state... [id=0e346a51831a9bc96fd9ea142f8c35b4e1ade12b]
module.keypair.local_file.private_key_pem[0]: Refreshing state... [id=b7ac3f7125c4e3681fd38539b220c1abf01d1254]
module.keypair.null_resource.chmod[0]: Refreshing state... [id=1854006565944356631]
module.keypair.aws_key_pair.generated: Refreshing state... [id=terraform-nyl-ant-key]
module.server[0].aws_instance.web[1]: Refreshing state... [id=i-047d4d406e22e87f9]
module.server[1].aws_instance.web[0]: Refreshing state... [id=i-003fcdb877e575b26]
module.server[0].aws_instance.web[0]: Refreshing state... [id=i-0d16b6f6eda6b834e]
module.server[1].aws_instance.web[1]: Refreshing state... [id=i-03be3bf6ee29f5633]

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

### Step 15.1.3
After confirming a zero change plan, clean up the comments in your `main.tf` the reference the `Don't Delete these until instructed to`.

Modify the server count by changing the `server_count` variable in TFC and running a `terraform apply`.

### Step 15.1.4

Congratulations! You're now storing your variable definitions remotely and can control the behavior of your Terraform code by adjusting their values. With Terraform Cloud you are able to centralize and secure the variable definintions for your workspace.
