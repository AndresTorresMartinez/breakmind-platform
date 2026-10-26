# ADR-003: GitHub Actions authentication to AWS

## Status

Accepted — 2026-10-09

## Context

CI workflows need to call AWS (first to run `terraform plan`, later to deploy). They have to prove who they are without exposing a secret, and this repository is public.

## Options considered

### 1. IAM user with access keys stored as GitHub secrets

- ➕ Simple and well known.
- ➖ The keys are long-lived: if they leak, they work until someone rotates them.
- ➖ Rotation is manual, and the keys sit in a second system outside AWS.

### 2. OIDC federation with an IAM role

GitHub signs a short-lived token for each job. AWS checks the signature and the token claims, then hands out temporary credentials (1 hour).

- ➕ No secret to store, leak or rotate.
- ➕ AWS can check which repo and branch is asking.
- ➖ More moving parts to understand: provider, trust policy and claims.

## Decision

**Use OIDC federation (option 2)**, defined in `infra/terraform/modules/github-oidc/`:

- An OIDC provider for `token.actions.githubusercontent.com`, accepting audience `sts.amazonaws.com`.
- A role `breakmind-github-actions` whose trust policy requires `aud` to equal `sts.amazonaws.com` and `sub` to match this repository.
- The `sub` value includes GitHub's immutable owner and repository IDs (`owner@id/repo@id`). GitHub sends them in the claim, and they stop someone who later registers the same name from assuming the role.
- The role has no permission policies yet. Each one is added when a workflow needs it.
- The workflow reads the role ARN from the `AWS_ROLE_ARN` repository variable.

## Consequences

- ✅ There are no AWS keys in GitHub, and credentials expire on their own.
- ✅ The module takes the repository as a variable, so the repo-specific value stays in the root.
- ⚠️ The `sub` pattern accepts any branch or tag of this repository for now. It must be narrowed to `main` or a GitHub environment when the role gets write permissions.
- ⚠️ A role with write permissions should be separate from a read-only one used on pull requests.
- ⚠️ AWS allows one provider per URL per account, so a second repository needs the provider moved out of the module.
- ⚠️ The first `apply` runs locally with personal credentials, because OIDC cannot create itself.
- ℹ️ A denied `AssumeRoleWithWebIdentity` gives no reason. The `sub` that actually arrived is visible in CloudTrail (Event history), under `userIdentity.userName`.
