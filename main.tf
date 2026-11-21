
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  project = "terraform-codepipeline-lab"

  tags = {
    Project     = local.project
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket for pipeline artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "terraform-codepipeline-artifacts-"

  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket containing the source ZIP file
resource "aws_s3_bucket" "source" {
  bucket_prefix = "terraform-codepipeline-source-"

  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for CodePipeline
resource "aws_iam_role" "pipeline" {
  name = "terraform-codepipeline-lab-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

# Permissions for CodePipeline to use S3 and CodeBuild
resource "aws_iam_role_policy" "pipeline" {
  name = "terraform-codepipeline-lab-policy"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/*",
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.source.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = [
          aws_codebuild_project.lab.arn
        ]
      }
    ]
  })
}

# IAM role for CodeBuild
resource "aws_iam_role" "build" {
  name = "terraform-codepipeline-build-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

# Permissions for CodeBuild
resource "aws_iam_role_policy" "build" {
  name = "terraform-codepipeline-build-policy"
  role = aws_iam_role.build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      }
    ]
  })
}

# CodeBuild project used by the pipeline
resource "aws_codebuild_project" "lab" {
  name         = "terraform-codepipeline-build"
  service_role = aws_iam_role.build.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - echo "CodePipeline build started"
            - echo "Terraform AWS CodePipeline lab"
    EOT
  }

  tags = local.tags
}

# CodePipeline with Source and Build stages
resource "aws_codepipeline" "lab" {
  name          = local.project
  role_arn      = aws_iam_role.pipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "S3Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket             = aws_s3_bucket.source.bucket
        S3ObjectKey          = "application.zip"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.lab.name
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.pipeline,
    aws_iam_role_policy.build,
    aws_s3_bucket_public_access_block.artifacts,
    aws_s3_bucket_public_access_block.source,
    aws_s3_bucket_server_side_encryption_configuration.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.source,
    aws_s3_bucket_versioning.source
  ]

  tags = local.tags
}
