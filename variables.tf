variable "cluster_name" {
    description = "Name of the cluster"
    type        = string
}

variable "custom_tags" {
    description = "Custom tags to be added to resources"
    type = map(string)
    default = {}
}

variable "alb_subnets" {
    description = "The subnets to deploy the ALB into"
    type = list(string)
}

variable "vpc_id" {
    description = "The VPC to deploy the resources into"
    type = string
}

variable "certificate_arn" {
    description = "The ARN of the certificate to use for HTTPS"
    type = string
}

variable "server_port" {
    description = "The port the web server will listen on"
    type = number
    default = 80
}