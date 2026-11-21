output "pipeline_name" {
  description = "Name of the planned CodePipeline."
  value       = aws_codepipeline.lab.name
}

output "pipeline_arn" {
  description = "ARN of the planned CodePipeline."
  value       = aws_codepipeline.lab.arn
}

output "source_bucket_name" {
  description = "S3 bucket for source ZIP files."
  value       = aws_s3_bucket.source.bucket
}

output "artifact_bucket_name" {
  description = "S3 bucket for pipeline artifacts."
  value       = aws_s3_bucket.artifacts.bucket
}

output "codebuild_project_name" {
  description = "CodeBuild project used by the pipeline."
  value       = aws_codebuild_project.lab.name
}
