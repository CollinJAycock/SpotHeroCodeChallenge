resource "aws_s3_bucket" "SpotHero-source" {
  bucket        = "spothero-image-source"
  acl           = "private"
  force_destroy = true
}

resource "aws_iam_role" "SpotHero-codepipeline-role" {
  name               = "SpotHero-codepipeline-role"

  assume_role_policy = file("${path.module}/policies/codepipeline_role.json")
}

/* policies */
data "template_file" "codepipeline_policy" {
  template = "${file("${path.module}/policies/codepipeline.json")}"

  vars  ={
    aws_s3_bucket_arn = aws_s3_bucket.SpotHero-source.arn
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.SpotHero-codepipeline-role.id
  policy = data.template_file.codepipeline_policy.rendered
}

/*
/* CodeBuild
*/
resource "aws_iam_role" "SpotHero-Build-Role" {
  name               = "SpotHero-Build-Role"
  assume_role_policy = file("${path.module}/policies/codebuild_role.json")
}

data "template_file" "codebuild_policy" {
  template = file("${path.module}/policies/codebuild_policy.json")

  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.SpotHero-source.arn
  }
}

resource "aws_iam_role_policy" "SpotHero-Build-Policy" {
  name        = "SpotHero-Build-Policy"
  role        = aws_iam_role.SpotHero-Build-Role.id
  policy      = data.template_file.codebuild_policy.rendered
}

data "template_file" "buildspec" {
  template = file("${path.module}/buildspec.yml")

  vars = {
    repository_url     = var.repository_url
    region             = var.region
    cluster_name       = var.ecs_cluster_name
    subnet_id          = var.run_task_subnet_id[1]
    security_group_ids = join(",", var.run_task_security_group_ids)
  }
}


resource "aws_codebuild_project" "SpotHero-build" {
  name          = "SpotHero-build"
  build_timeout = "10"
  service_role  = aws_iam_role.SpotHero-Build-Role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image           = "aws/codebuild/docker:1.12.1"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec.rendered
  }
}

/* CodePipeline */

resource "aws_codepipeline" "SpotHero-pipeline" {
  name     = "SpotHero-pipeline"
  role_arn = aws_iam_role.SpotHero-codepipeline-role.arn

  artifact_store {
    location = aws_s3_bucket.SpotHero-source.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner      = "docker-training"
        Repo       = "webapp"
        Branch     = "master"
        OAuthToken = var.GitHub_OAuth_Token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["imagedefinitions"]

      configuration = {
        ProjectName = "SpotHero-build"
      }
    }
  }

  stage {
    name = "Production"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}