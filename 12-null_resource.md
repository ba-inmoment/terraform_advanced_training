# Lab 1: Null Resource

Duration: 15 minutes

This lab demonstrates the use of the `null_resource`. Instances of `null_resource` are treated like normal resources, but they don't do anything. Like with any other resource, you can configure provisioners and connection details on a null_resource. You can also use its triggers argument and any meta-arguments to control exactly where in the dependency graph its provisioners will run.

- Task 1: Create a AWS Instance using Terraform
- Task 2: Use `null_resource` with a VM to take action with `triggers`.

We'll demonstrate how `null_resource` can be used to take action on a set of existing resources that are specified within the `triggers` argument

## Task 1: Create a AWS Instances using Terraform
### Step 16.1.1: Create Server instances

Build the yeweb servers using the AWS Server Modules (previous labs)

You can see this now if you run `terraform apply`:

```text
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

public_dns = [
  [
    "ec2-3-85-82-103.compute-1.amazonaws.com",
  ],
]
public_ip = [
  [
    "3.85.82.103",
  ],
]
```

If you inspect the terraform state file with a `terraform state list` you will see that the `keypair` module already makes use of `null_resource` to change permissions of a keypair file.

```bash
terraform state list

module.keypair.aws_key_pair.generated
module.keypair.local_file.private_key_pem[0]
module.keypair.local_file.public_key_openssh[0]
module.keypair.null_resource.chmod[0]
module.keypair.tls_private_key.generated
module.server[0].data.aws_ami.ubuntu_16_04
module.server[0].aws_instance.web[0]
```

```bash
terraform state show module.keypair.null_resource.chmod[0]

# module.keypair.null_resource.chmod[0]:
resource "null_resource" "chmod" {
    id       = "6131828039692054403"
    triggers = {
        "key" = <<-EOT
            -----BEGIN RSA PRIVATE KEY-----
            MIIEowIBAAKCAQEAv6HeC99ahZWLBdmv1/cmT+yqoHQxN4uPacrFu7GdwJGCPV21
            ZetKy295rrPwDSnAfHtzIV0dtslh0DfEfq6cbLzikQm1OQaHMbHlwpBKluECvHix
            6pwdQFoGV3H5MPt0hFuBelYY/R9Fnp7Cfel8U2gPecBhtDxhK7wK/V7TA8dgwuV2
            dS/clzwCie2L0zHJI+OaEnRNuYlbc+hEDdmizlSyM5EF6y10dXFa25Py1Q7SF/ym
            2HhrEymAYSowjplPJQZLGB44bjF48tgwHeBQ06igyeUZDCSMK4XSWNHBxLE+0eYe
            RWrvNvd88k793+zt8tdoTMHXm9zHDcVJ+dcBTwIDAQABAoIBADIqKXpqKcQ2dYI+
            ji224SyjA7elMw0bV5uWHVUZFfbHIJT35vibM6U1tWDqcbjAaUcs+eKOAa1L4nMj
            ZijThNdiSt008V/QOavkqgTYyO3eUV0NK2YDIBUse+SATX9pFANiAO8JgtkgSpVP
            chKMAKPE5eg1WF5aQAW24BmbrRmbr3YrToob4ApHSbIgGnQLDS7CcqTSzHWEiTlC
            wcJr+5ChnAdKsHubR6JydnW1cUS+sgX8YtpQ2Wi7DrqZjMiahMUTWpRY50UUkj3X
            veG9mijxxqrsafpereQIPaQ4hBAL5zdk7pLNSV+Y4u6oMrc+s6KUVSywJOfwNoPS
            sAS7zYECgYEAy7RMdGy4GMjtje+I5WXdwLwq0XrD81VpeVmJgw8wjc/Ed29u+WP9
            eSozIrGUDc9GBa7jGbswug8XImWf/N2Cd08C0nuTVdBEXN2dsohBg5Syod2L+nmU
            iELGKbUzmSif70fMiDLmOnTJbGyRC/1YkDdDZ5yRHrWcyuMvuQBgg1ECgYEA8NQu
            kw2BV633QJgZIv4q48om8iVdm2LbM5wDB1lMxn7+V+FW4DSkn1lq2idQqstpE/c9
            Wev7iMNNw6pcT7Z4tdHz9R/NnyPtW8sRIZVy7s/iICilckXLZohDAZEVHJqiuHsO
            dHjieP+BSnxiTc/vleEuiZinW3y0ozs4GRId0p8CgYAt/uIcj8fp4MSy/dk9Ywj1
            UgehEUVZlnmgavU/4JgoDTfheAnoygkb6MlvFgXGMH0xH1IsJzZTbMDehW/gmuuw
            oOiUOk8EW2h0R54qB9YzLco//lRzFCzTr7ArDr094gxq7R1jy4psvJ4Wm1UNDgGH
            XtMbfCDQfFWRAkduUIV6YQKBgQC4ztr+1fpPwpxe4VlI1SssqtDAOZRfzbjRHgPk
            +85C9OlRnwb//uXlssSgrFLm/jmgrLZT7xeTl+xxHqbANRLk1D0V+lXcrcFUE70N
            vJX6VWT9sLNlwdGY2TAyX5eH39LHJwessad5mvkoo9L8S3lb1vXTeWXUexpTuPoP
            oytnmQKBgAHQte6sR/TSK3ex044Z38pJm3VtZIEjK5oF0chDQACKiF7/wiN39qDH
            314CdV9lqQ6L1RMOyZ0MMBHljbVGGVjHx3dRKkr2j/dJqTpxKJqOoRVBJAFAKZ52
            PuAQD4K6akrMTFGmPrMu0wnN6wRtPjfurI2YXVqMH+EJl4SncTpZ
            -----END RSA PRIVATE KEY-----
        EOT
    }
}
```

## Task 2: Use `null_resource` with an EC2 instance to take action with `triggers`
### Step 16.2.1: Use `null_resource`

Add `null_resource` stanza to the `server.tf`.  Notice that the trigger for this resource is set to a timestamp for the Message of the day so we should add a variable block to our `server.tf` to include a Message of the Day.

```hcl
variable "MessageOfTheDay" {
  default = "Terraform Rocks"
}

resource "null_resource" "MessageOfTheDay" {

  depends_on = [
    aws_instance.web,
  ]

  triggers = {
    MessageOfTheDay = timestamp()
  }

  provisioner "remote-exec" {
    connection {
      host        = element(aws_instance.web.*.public_ip, 0)
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
    }

    inline = [
      "sudo apt update",
      "sudo apt-get install -y cowsay",
      "cowsay ${var.MessageOfTheDay}"
    ]

  }
}
```
Initialize the configuration with a `terraform init` followed by a `plan` and `apply`.

### Step 16.2.2: Re-run `plan` and `apply` to trigger `null_resource`
After the infrastructure has completed its buildout, re-run a plan and apply and notice if the null resource is triggered.  If you modify the `count` vaule of your `aws_instance` the null resource will be triggered.

```shell
terraform apply
```

Run `apply` a few times to see the `null_resource`.

### Step 16.2.3: Destroy
Finally, run `destroy`.

```shell
terraform destroy
```
