resource "aws_security_group" "rds" {
  name        = "rds"
  description = "RDS security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      module.autoscaling_sg.security_group_id,
      aws_security_group.bastion_host.id
    ]
  }
}

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

  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  manage_master_user_password = true
}
