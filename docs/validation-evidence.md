# AWS CodePipeline Validation Evidence

## Environment

- AWS account: `774305591665`
- IAM user: `3rd-lab-user`
- AWS region: `us-east-1`
- Terraform version: `1.17.0`
- Project: `terraform-aws-codepipeline-lab`

## AWS Discovery

Command:

```bash
aws codepipeline list-pipelines --region us-east-1
```

Observed result:

```json
{
  "pipelines": []
}
```

Pipeline count: `0`.

## Terraform Validation

Command:

```bash
terraform validate
```

Observed output:

```text
Success! The configuration is valid.
```

## Terraform Plan

Command:

```bash
terraform plan -input=false -no-color
```

Observed output:

```text
Plan: 13 to add, 0 to change, 0 to destroy.
```

## Planned Resources

- 2 S3 buckets
- 2 S3 public access block configurations
- 2 S3 encryption configurations
- 1 S3 versioning configuration
- 2 IAM service roles
- 2 IAM inline role policies
- 1 CodeBuild project
- 1 CodePipeline pipeline

**Total: 13 planned AWS resources.**

## Deployment Status

**PLAN ONLY — NOT DEPLOYED.**

No `terraform apply` was executed.

No AWS resources were created or modified by this lab.

No CodePipeline execution or CodeBuild build was tested.

## Screenshot

`screenshots/codepipeline-terraform-validation.png` — actual terminal evidence of successful Terraform validation and planning.

