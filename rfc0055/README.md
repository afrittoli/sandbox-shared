# RFC-0055 POC: OIDC Federation + IAM Prefix Scoping

This proof of concept validates the security model proposed in
[RFC-0055](https://github.com/pytorch/rfcs/pull/55) for out-of-tree platform
vendors uploading build artifacts to a shared S3 bucket via GitHub Actions
OIDC federation.

## PyTorch Mapping

| POC Repository              | PyTorch Equivalent         | Role                                           |
|-----------------------------|----------------------------|-------------------------------------------------|
| `afrittoli/sandbox-shared`  | `pytorch/test-infra`       | Shared infrastructure: reusable workflow, composite action, Terraform |
| `afrittoli/sandbox`         | Vendor repo (e.g. platform vendor 1) | Platform 1 — calls shared workflow to upload artifacts |
| `afrittoli/sandbox-2`       | Vendor repo (e.g. platform vendor 2) | Platform 2 — calls shared workflow to upload artifacts |

## Architecture

```
                  ┌─────────────────────────────-───-─┐
                  │         AWS Account               │
                  │                                   │
                  │  ┌───────────────────────────-┐   │
                  │  │  S3: afrittoli-rfc0055-poc │   │
                  │  │  ├── platform1/*           │   │
                  │  │  └── platform2/*           │   │
                  │  └──────────────────────────-─┘   │
                  │         ▲              ▲          │
                  │         │              │          │
                  │  ┌──────┴───┐   ┌──────┴───┐      │
                  │  │ IAM Role │   │ IAM Role │      │
                  │  │platform1 │   │platform2 │      │
                  │  └──────┬───┘   └──────┬───┘      │
                  │         │              │          │
                  │     OIDC Trust     OIDC Trust     │
                  │         │              │          │
                  └─────────┼──────────────┼──────────┘
                            │              │
              ┌─────────────┼──────────────┼──────────────┐
              │  GitHub     │              │              │
              │             │              │              │
              │  ┌──────────┴──────────────┴────────────┐ │
              │  │   afrittoli/sandbox-shared           │ │
              │  │   (pytorch/test-infra)               │ │
              │  │                                      │ │
              │  │   shared-build.yml (reusable)        │ │
              │  │     └─► s3-upload-with-role (action) │ │
              │  └──────────┬───────────────┬───────────┘ │
              │             │               │             │
              │    workflow_call       workflow_call      │
              │             │               │             │
              │  ┌──────────┴──┐   ┌────────┴────────┐    │
              │  │ afrittoli/  │   │ afrittoli/      │    │
              │  │ sandbox     │   │ sandbox-2       │    │
              │  │ (vendor 1)  │   │ (vendor 2)      │    │
              │  └─────────────┘   └─────────────────┘    │
              └───────────────────────────────────────────┘
```

## Security Model

Three layers of enforcement, all configured in AWS IAM:

1. **Repo scoping** — Each IAM role's trust policy only accepts OIDC tokens
   from a specific GitHub repository (`sub` claim matches `repo:<org>/<repo>:*`).

2. **Prefix scoping** — Each role's permission policy restricts S3 writes to
   a specific prefix (`platform1/*` or `platform2/*`), preventing
   cross-platform writes.

3. **Workflow enforcement** — Each role's trust policy requires that the OIDC
   token's `job_workflow_ref` claim matches the shared reusable workflow. This
   prevents vendor repos from bypassing the shared workflow and assuming the
   role directly.

## Tests Executed

### Happy Path

| # | Test | Repo | Workflow | Result |
|---|------|------|----------|--------|
| 1 | Platform 1 uploads to `platform1/` | `sandbox` | `platform-build.yml` | ✅ Pass |
| 2 | Platform 2 uploads to `platform2/` | `sandbox-2` | `platform-build.yml` | ✅ Pass |

### Negative Tests — Prefix Scoping

| # | Test | Repo | Workflow | Result |
|---|------|------|----------|--------|
| 3 | Platform 1 writes to `platform2/` prefix | `sandbox` | `platform-build.yml` (prefix override) | ✅ Denied |

Platform 1's role can assume credentials via OIDC but the S3 permission
policy blocks writes outside its own prefix.

### Negative Tests — Role Scoping

| # | Test | Repo | Workflow | Result |
|---|------|------|----------|--------|
| 4 | Sandbox assumes platform2's role | `sandbox` | `negative-cross-role.yml` | ✅ Denied |

The OIDC `sub` claim (`repo:afrittoli/sandbox:*`) does not match platform2's
trust policy (`repo:afrittoli/sandbox-2:*`), so `AssumeRoleWithWebIdentity`
is rejected.

### Negative Tests — Workflow Bypass

| # | Test | Repo | Workflow | Result |
|---|------|------|----------|--------|
| 5 | Direct role assumption (before `job_workflow_ref` enforcement) | `sandbox` | `negative-bypass-shared.yml` | ⚠️ Allowed |
| 6 | Direct role assumption (after `job_workflow_ref` enforcement) | `sandbox` | `negative-bypass-shared.yml` | ✅ Denied |

Without the `job_workflow_ref` condition, any workflow in the vendor repo
could assume the role directly, bypassing the shared workflow. Adding a
`job_workflow_ref` condition to the IAM trust policy closes this gap —
**no changes to GitHub OIDC subject claim configuration are required**.

## Workflow Enforcement via `job_workflow_ref`

AWS IAM supports `token.actions.githubusercontent.com:job_workflow_ref` as a
condition key in OIDC trust policies. This allows the shared infrastructure
owner to enforce that vendor repos must go through the shared reusable
workflow to upload artifacts, without requiring any GitHub-side configuration
changes (no subject claim customization needed).

In this POC, each IAM role's trust policy includes a `StringEquals` condition
on `job_workflow_ref` matching the shared workflow ref. Any attempt to assume
the role from a workflow that is not the shared reusable workflow is denied.

## Repository Contents

```
sandbox-shared/
├── .github/
│   ├── actions/
│   │   └── s3-upload-with-role/     # Composite action: OIDC + S3 upload
│   │       └── action.yml
│   └── workflows/
│       └── shared-build.yml         # Reusable workflow (workflow_call)
├── terraform/                       # AWS infrastructure
│   ├── main.tf                      # Provider config
│   ├── variables.tf                 # Region, bucket name, org, workflow ref
│   ├── oidc.tf                      # GitHub Actions OIDC provider
│   ├── s3.tf                        # S3 bucket with public access blocked
│   ├── roles.tf                     # IAM roles + trust/permission policies
│   └── outputs.tf                   # Role ARNs, bucket name/ARN
└── rfc0055/
    ├── README.md                    # This file
    ├── sandbox-build.yml            # Caller workflow for afrittoli/sandbox
    └── sandbox-2-build.yml          # Caller workflow for afrittoli/sandbox-2
```

## Cleanup

```bash
cd terraform
terraform destroy
```

This removes all AWS resources (S3 bucket, OIDC provider, IAM roles).
