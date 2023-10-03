data "aws_ssm_patch_baseline" "al2023" {
  owner            = "AWS"
  name_prefix      = "AWS-"
  operating_system = "AMAZON_LINUX_2023"
}

data "aws_caller_identity" "current" {}

resource "aws_ssm_patch_group" "ecs" {
  baseline_id = data.aws_ssm_patch_baseline.al2023.id
  patch_group = "ecs"
}

resource "aws_ssm_maintenance_window" "ecs" {
  name     = "ecs"
  schedule = "cron(0 0 0 ? * SUN *)"
  duration = 2
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "ecs" {
  name          = "ecs"
  window_id     = aws_ssm_maintenance_window.ecs.id
  resource_type = "INSTANCE"
  targets {
    key    = "tag:Patch Group"
    values = [aws_ssm_patch_group.ecs.id]
  }
  owner_information = "ECS"
}

resource "aws_ssm_maintenance_window_task" "main" {
  max_concurrency = 1
  max_errors      = 1
  priority        = 1
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.ecs.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.ecs.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Scan"]
      }

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}
