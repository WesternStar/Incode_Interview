module "dns" {
  source = "./modules/dns"

  domain_name = var.domain_name

  tags = {
    Name = var.domain_name
  }
}
