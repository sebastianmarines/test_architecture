module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
}
