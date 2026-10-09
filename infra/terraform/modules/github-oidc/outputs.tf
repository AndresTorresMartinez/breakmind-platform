output "role_arn" {
  description = "ARN from the role that github actions use with OIDC"
  value       = aws_iam_role.github_actions.arn
}