//IAM Data and Resources
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_role.id
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = file("${path.module}/policies/ecs-task-execution-role.json")
}
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = file("${path.module}/policies/ecs-execution-role-policy.json")
  role   = aws_iam_role.ecs_execution_role.id
}


resource "aws_ecr_repository" "SpotHero-Repo" {
  name = "spothero-repo"
}

data "aws_ecr_repository" "SpotHero-Repo" {
  name = "spothero-repo"
}
resource "aws_ecs_cluster" "SpotHero-ECS-Cluster" {
  name = "SpotHero-ECS-Cluster"
}

resource "aws_ecs_service" "SpotHero-ECS" {
  name            = "SpotHero_ECS"
  task_definition = aws_ecs_task_definition.SpotHero_ECS_Task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  depends_on      = [aws_iam_role.ecs_role,aws_lb.SpotHeroLoadBalancer,aws_lb_target_group.SpotHero_LoadBalance-TargetGroup]
  cluster         = aws_ecs_cluster.SpotHero-ECS-Cluster.id
  health_check_grace_period_seconds = 300

  network_configuration{
    subnets = var.subnet_ids
    security_groups = [aws_security_group.SpotHero-web-inbound-securityGroup.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.SpotHero_LoadBalance-TargetGroup.arn
    container_name   = "spothero-image"
    container_port   = 80
  }
}

/* the task definition for the web service */
data "template_file" "web_task" {
  template = "${file("${path.module}/tasks/spot-hero-def.json")}"

  vars = {
    image  = aws_ecr_repository.SpotHero-Repo.repository_url
  }
}

resource "aws_ecs_task_definition" "SpotHero_ECS_Task" {
  family                   = "SpotHero_ECS_Task"
  container_definitions    = data.template_file.web_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
}

resource "aws_lb" "SpotHeroLoadBalancer" {
  name               = "SpotHeroLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SpotHero-web-inbound-securityGroup.id]
  subnets            = var.subnet_ids
  enable_deletion_protection = false
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_lb.SpotHeroLoadBalancer.arn
  port              = "80"  
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.SpotHero_LoadBalance-TargetGroup]

  default_action {    
    target_group_arn = aws_lb_target_group.SpotHero_LoadBalance-TargetGroup.arn
    type             = "forward"  
  } 
}

resource "aws_lb_target_group" "SpotHero_LoadBalance-TargetGroup" {
  name     = "SpotHero-LoadBalance-TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check{
    interval = 300
    matcher = "200-299"
  }

    lifecycle {
    create_before_destroy = true
  }
}

/* security group for ALB */
resource "aws_security_group" "SpotHero-web-inbound-securityGroup" {
  name        = "SpotHero-web-inbound-securityGroup"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}