variable "ami" {}
variable "subnet_id" {}
variable "vpc_security_group_ids" {
  type = list(any)
}
variable "identity" {}

variable "key_name" {}
variable "private_key" {}

variable "num_webs" {
  default = "2"
}


resource "aws_instance" "web" {
  count                  = var.num_webs
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name = var.key_name


  connection {
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "assets"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /tmp/assets/setup-web.sh",
    ]
  }

  tags = {
    "Identity"    = var.identity
    "Name"        = "Student"
    "Environment" = "Training"
  }
}

output "public_ip" {
  value = aws_instance.web.*.public_ip
}

output "public_dns" {
  value = aws_instance.web.*.public_dns
}