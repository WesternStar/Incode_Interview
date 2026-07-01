variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT gateway for private subnet egress"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single shared NAT gateway instead of one per AZ"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Whether to provision one NAT gateway per AZ (ignored if single_nat_gateway is true)"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the VPC"
  type        = map(string)
  default     = {}
}
