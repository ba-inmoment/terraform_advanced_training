provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


module "server" {
  source = "./server"

  ami                    = var.ami
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  identity               = var.identity
  key_name               = module.keypair.key_name
  private_key            = module.keypair.private_key_pem
}

module "keypair" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "2.0.0"
  path    = "${path.root}/keys"
  name    = "${var.identity}-key"
}
