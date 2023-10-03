module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.2.2"

  cluster_name = local.name

  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    ex-1 = {
      auto_scaling_group_arn         = module.autoscaling["ex-1"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.2"

  name        = local.name
  cluster_arn = module.ecs_cluster.cluster_arn

  memory = 256

  requires_compatibilities = ["EC2"]
  capacity_provider_strategy = {
    ex-1 = {
      capacity_provider = module.ecs_cluster.autoscaling_capacity_providers["ex-1"].name
      weight            = 1
      base              = 1
    }
  }

  volume = {
    my-vol = {}
  }

  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]

      # entry_point = ["/usr/sbin/apache2", "-D", "FOREGROUND"]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.alb.target_group_arns, 0)
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb_sg.security_group_id
    }
  }
}

