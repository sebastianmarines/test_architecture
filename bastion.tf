resource "aws_security_group" "bastion_host" {
  name        = "bastion_host"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_instance_profile" "bastion_host" {
  name = "bastion_host"
  role = aws_iam_role.bastion_host.name
}

resource "aws_iam_role" "bastion_host" {
  name = "bastion_host"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_host" {
  role       = aws_iam_role.bastion_host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

module "bastion_host" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name          = "${local.name}-bastion-host"
  ami           = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.insecure_value).image_id
  instance_type = "t3.small"

  key_name = var.ec2_key_pair_name

  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.bastion_host.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.bastion_host.name

  instance_tags = {
    "Patch Group" = "bastion-hosts"
  }
}
