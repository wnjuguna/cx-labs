terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  cluster_name = "${var.thing_name}${var.name_suffix}"
  # NLBs have very short name requirements. Also, the name isn't very important
  nlb_prefix = substr(var.thing_name, 0, 8)
}

# Find the ECS-recommended AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_iam_role" "ecs_instance" {
  # Truncate thing_name to keep IAM role name_prefix < 38 chars
  name_prefix = "${substr(var.thing_name, 0, 27)}-ecs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name_prefix = "${var.thing_name}-ecs-"
  role        = aws_iam_role.ecs_instance.name
}

resource "aws_security_group" "ecs_instances" {
  name_prefix = "${var.thing_name}-ecs-"
  description = "ECS EC2 instances for ${local.cluster_name}"
  vpc_id      = var.vpc_id

  # NLB target group health checks and OTLP traffic (Coralogix collector)
  ingress {
    description = "OTLP gRPC"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  ingress {
    description = "OTLP HTTP"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.thing_name}-ecs-instances"
  }
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.thing_name}-lt-"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_ami.value).image_id
  instance_type = var.ecs_node_type

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_instance.arn }
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    echo "ECS_CLUSTER=${local.cluster_name}" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config

    # Install/enable the CloudWatch Agent so we can capture container stdout
    yum update -y || true
    yum install -y amazon-cloudwatch-agent || true

    cat > /etc/amazon-cloudwatch-agent/config.json <<CWCFG
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "${aws_cloudwatch_log_group.sys_messages.name}",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/lib/docker/containers/*/*.log",
                "log_group_name": "${aws_cloudwatch_log_group.containers.name}",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/ecs/ecs-agent.log*",
                "log_group_name": "${aws_cloudwatch_log_group.ecs_agent.name}",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
CWCFG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -m ec2 -c file:/etc/amazon-cloudwatch-agent/config.json || true

  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.thing_name}-ecs-instance"
    }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.thing_name}-ecs-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.ecs_min_nodes
  max_size            = var.ecs_max_nodes
  desired_capacity    = var.ecs_desired_nodes

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  # Give instances time to boot and start the OTLP collector before NLB health checks
  health_check_grace_period = 300
  health_check_type         = "EC2"

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch  = true
  }
  # Register ASG instances with the Coralogix NLB target groups (added below)
  target_group_arns = [
    aws_lb_target_group.otlp_http.arn,
    aws_lb_target_group.otlp_grpc.arn,
  ]
}

# Internal NLB for the OTel traffic shouldn't be _necessary_ given that CX runs as a daemonset,
# but it will be necessary if we add fargate support later, so let's do it now:
resource "aws_lb" "coralogix_nlb" {
  name               = "${local.nlb_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  ip_address_type    = "ipv4"

  tags = {
    Name = "${var.thing_name}-coralogix-nlb"
  }
}

resource "aws_lb_target_group" "otlp_http" {
  name     = "${local.nlb_prefix}-otlp-h"
  port     = 4318
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = "4318"
    interval = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "otlp_grpc" {
  name     = "${local.nlb_prefix}-otlp-g"
  port     = 4317
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = "4317"
    interval = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "otlp_http" {
  load_balancer_arn = aws_lb.coralogix_nlb.arn
  port              = 4318
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp_http.arn
  }
}

resource "aws_lb_listener" "otlp_grpc" {
  load_balancer_arn = aws_lb.coralogix_nlb.arn
  port              = 4317
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp_grpc.arn
  }
}

/* Attach the ASG to the NLB target groups by setting the ASG's target_group_arns.
   We can't directly reference the ASG resource's block here because it is
   declared above; we'll patch the ASG to include the ARNs dynamically via
   a local-to-local assignment below using a null resource trick is unnecessary
   — instead we update the ASG's `target_group_arns` attribute in-place when
   the target groups exist. */


# Lookup EC2 instances created by the ASG so we can expose their private IPs
data "aws_instances" "ecs_asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.ecs_asg.name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.9.0"

  cluster_name = local.cluster_name

  cluster_setting = [
    { name = "containerInsights", value = "enabled" }
  ]

  autoscaling_capacity_providers = {
    ec2 = {
      auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
      managed_draining               = "ENABLED"
      managed_termination_protection = "DISABLED"
    }
  }

  default_capacity_provider_strategy = {
    ec2 = {
      weight = 1
      base   = var.ecs_min_nodes
    }
  }

  cluster_tags = {
    Environment = "lab"
    Team        = var.cx_team_name
    Owner       = var.user
  }
}

resource "aws_iam_role" "task_exec" {
  # Truncate thing_name to keep IAM role name_prefix < 38 chars
  name_prefix = "${substr(var.thing_name, 0, 27)}-ecs-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Coralogix OTel distro
module "ecs-ec2" {
  source                              = "coralogix/aws/coralogix//modules/ecs-ec2"
  ecs_cluster_name                    = module.ecs_cluster.cluster_arn
  image_version                       = "v0.5.0"
  coralogix_region                    = var.cx_region
  default_application_name            = var.thing_name
  default_subsystem_name              = var.thing_name
  api_key                             = var.cx_data_key
}




resource "aws_cloudwatch_log_group" "ecs_agent" {
  name              = "/${var.thing_name}/ecs-agent"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "sys_messages" {
  name              = "/${var.thing_name}/var/log/messages"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "containers" {
  name              = "/${var.thing_name}/containers"
  retention_in_days = 1
}

resource "aws_iam_role_policy_attachment" "cwagent_attach" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
