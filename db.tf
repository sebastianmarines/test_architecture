module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.1"

  identifier = local.name

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.medium"
  allocated_storage = 5

  major_engine_version = "5.7"
  family               = "mysql5.7"

  db_name  = local.name
  username = "admin"
  port     = 3306

  multi_az = true

  iam_database_authentication_enabled = true

  subnet_ids = module.vpc.database_subnets
}
