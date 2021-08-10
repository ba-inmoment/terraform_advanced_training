# Lab 20: Template Creation using Packer

Duration: 30 minutes

### Creating a Packer Image

To build an image packer utilizes a configuration file with the following sections...

##### [Builders](https://www.packer.io/docs/builders/index.html) (required)
* responsible for creating machines and generating images from them for various platforms.
* You can have multiple builder types in one file.


##### [Source](https://www.packer.io/docs/templates/hcl_templates/blocks/source) (required)
* defines reusable builder configuration blocks

Below is an example of a basic builder block that uses an AWS EBS source for creating an AWS EBS AMI.

1. Create a new packer configuration file called `web-visitors.pkr.hcl` with the following configuration.

```hcl
variable "aws_source_ami" {
  type    = string
  default = "ami-039a49e70ea773ffc"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "web_visitors" {
  ami_name      = "tmp-${local.timestamp}"
  instance_type = "t1.micro"
  region        = "us-east-1"
  source_ami    = var.aws_source_ami
  ssh_username  = "ubuntu"
  tags = {
    Created-by = "Packer"
    OS_Version = "Ubuntu"
    Release    = "Latest"
    App        = "Web Visitors"
  }
}

build {
  sources = ["source.amazon-ebs.web_visitors"]

  provisioner "shell" {
    inline = ["mkdir ~/src", "cd ~/src", "git clone https://github.com/hashicorp/demo-terraform-101.git", "cp -R ~/src/demo-terraform-101/assets /tmp", "sudo sh /tmp/assets/setup-web.sh"]
  }

}
```

##### [Variables](https://www.packer.io/docs/templates/user-variables.html)
* Input variables allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files.
    * **Note**: these can be definied within the main Packer configuration file and also be passed from an additional variable file.
    
    
##### [Provisioners](https://www.packer.io/docs/provisioners/index.html)
* use builtin and third-party software to install and configure the machine image after booting. Provisioners prepare the system for use, so common use cases for provisioners include:
    * installing packages 
    * patching 
    * creating users 
    * downloading application code
    
   
##### Running Packer
Once the file is ready we will need to dothe following steps...

1. **packer validate web-vistors.pkr.hcl** - If properly formatted the file will successfully validate
    * This command will work just fine if all the variables are within the main packer file, but if you want to pass user variables from a different file the command will have an additional flag **packer validate web-vistors.pkr.hcl**

Validate your configuration.

```shell
packer validate web-visitors.pkr.hcl
```

2. Format your Packer Configuration File

```shell
packer fmt web-visitors.pkr.hcl
```

3. Initiate the Image Build
   
```shell
packer build web-visitors.pkr.hcl
```

##### Resources
* Packer [Docs](https://www.packer.io/docs/index.html)
* Packer [CLI](https://www.packer.io/docs/commands/index.html)
