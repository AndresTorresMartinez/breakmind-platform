# ADR-002: Terraform state backend

## Status

Accepted — 2026-09-30

## Context

Terraform records every resource it creates in a state file. `plan` compares that state with the code and with what really exists in AWS to decide what to change.

By default the state lives on the local disk. That causes two problems:

- **Losing the laptop means losing the state.** The resources keep running in AWS, but Terraform no longer knows it created them. A new `apply` tries to create them again and fails on name conflicts (for example, S3 bucket names). The only way back is to run `terraform import` for each resource.
- **Git is not a safe place for it.** The state stores resource attributes in plain text, including secrets such as database passwords, and this repository is public. Git also has no lock, so two copies of the state can drift apart and overwrite each other.

The state needs a remote home with versioning, encryption, no public access and a lock that stops two `apply` runs at the same time.

## Options considered

### 1. S3 with native locking (`use_lockfile = true`)

Terraform writes a `.tflock` file next to the state in the same bucket, using S3 conditional writes.

- ➕ The state and the lock live in one place, so there is nothing extra to create or maintain.
- ➕ It is the current recommended approach (Terraform ≥ 1.10).
- ➖ It requires Terraform 1.10 or newer.

### 2. S3 + DynamoDB lock table

A DynamoDB table holds the lock record, and S3 holds the state.

- ➕ It was the original standard, so it is common in existing codebases.
- ➖ It is one more resource to create, secure and pay for, only to prevent overwrites.
- ➖ It has been deprecated since Terraform 1.11.

### 3. HCP Terraform (formerly Terraform Cloud)

HashiCorp's managed service stores the state, handles locking and can run `plan`/`apply` remotely.

- ➕ No bucket to manage, and it includes a web UI and run history.
- ➖ It adds a second vendor and account outside AWS, and the state leaves the AWS account.
- ➖ One goal of this project is to learn AWS-native infrastructure, and this option hides that part.

## Decision

**Use S3 with native locking (option 1).**

- `infra/terraform/bootstrap/` creates the bucket `breakmind-platform-state` with versioning, SSE-S3 encryption, all four public access blocks and `prevent_destroy` on the bucket, versioning and public access block.
- `infra/terraform/` stores its state at `staging/breakmind-base.tfstate` in that bucket with `use_lockfile = true`.

**The bootstrap project keeps its own state local on purpose.** If its state lived inside the bucket it manages, a damaged or deleted bucket would also remove the state needed to repair it. It is like keeping the spare car key inside the car. The bootstrap has a single operator, no CI access and only four resources, which can be recovered with `import` if needed.

## Consequences

- ✅ The application state survives losing the laptop and is ready for CI later.
- ✅ Versioning allows restoring an earlier state after a bad `apply`. Restoring the state does not roll back infrastructure, so a `plan` must follow every restore.
- ✅ There is no DynamoDB table to maintain.
- ⚠️ The bootstrap state is not backed up. If it is lost, the four resources must be re-imported by hand.
- ⚠️ The bootstrap is a manual first step that must run before anything else.
- ⚠️ `prevent_destroy` only guards against Terraform plans. It does not stop deletions from the AWS Console, and it disappears if the resource block is removed from the code.
- ℹ️ The state bucket uses SSE-S3 (the AWS default), not a customer-managed KMS key. That is enough for state files. KMS-managed encryption is planned for the data stores (RDS, EBS).
