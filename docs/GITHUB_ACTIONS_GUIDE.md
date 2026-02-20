# GitHub Actions CI/CD Guide

> **Related docs:** [OIDC Setup](OIDC_SETUP.md) · [Deployment](DEPLOYMENT.md) · [IAM Policy Reference](IAM_POLICY_REFERENCE.md)

---

## Workflows Overview

```
.github/workflows/
├── terraform-ci.yml    # Runs on PRs + pushes to main (validation)
└── terraform-cd.yml    # Runs on merges to main (deployment)
```

### CI Pipeline (`terraform-ci.yml`)

**Triggers:** Pull requests and pushes to `main` (only when `terraform/`, `lambda/`, or `.github/workflows/` change)

| Job | What it does |
|-----|-------------|
| `terraform-validate` | Format check → Init → Validate → Plan → Posts plan as PR comment |
| `python-lint` | Checks Python Lambda syntax + runs pylint |
| `security-scan` | GitLeaks (secret detection) + tfsec (Terraform security) |

### CD Pipeline (`terraform-cd.yml`)

**Triggers:** Push to `main` (when `terraform/`, `lambda/`, or `website/` change) + manual trigger via GitHub UI

| Step | What it does |
|------|-------------|
| Configure AWS | Authenticates via OIDC (no stored credentials) |
| Terraform Apply | `init` → `plan` → `apply` |
| Upload Website | `aws s3 sync` to website bucket |
| Invalidate CDN | Clears CloudFront cache |
| Summary | Reports deployment URLs |

Both workflows use **OIDC authentication** — no AWS secrets stored in GitHub. See [OIDC Setup](OIDC_SETUP.md).

---

## Setup (One Time)

```bash
# 1. Run OIDC setup script
./scripts/test-oidc.sh

# 2. Update AWS_ACCOUNT_ID in both workflow files
#    .github/workflows/terraform-ci.yml
#    .github/workflows/terraform-cd.yml

# 3. Push workflows
git add .github/
git commit -m "Add GitHub Actions CI/CD pipelines"
git push origin main
```

### Test it

```bash
git checkout -b test-cicd
echo "# test" >> terraform/main.tf
git add . && git commit -m "Test CI/CD" && git push origin test-cicd
```

Open a PR on GitHub → watch CI run → merge → watch CD deploy.

---

## Key Concepts

| Concept | What it means |
|---------|--------------|
| **Workflow** | A `.yml` file in `.github/workflows/` — one workflow = one automated process |
| **Event/Trigger** | What starts the workflow: `push`, `pull_request`, `workflow_dispatch` (manual), `schedule` |
| **Job** | A group of steps. Jobs run **in parallel** by default (use `needs:` for dependencies) |
| **Step** | A single task: either a shell command (`run:`) or a reusable action (`uses:`) |
| **Runner** | The machine that runs your job — `ubuntu-latest` (free, 2000 min/month) |
| **Secret** | Encrypted variable stored in repo Settings → Secrets → Actions |
| **Environment** | Optional protection rules (e.g., `production` requires manual approval) |

### Useful expressions

```yaml
${{ secrets.MY_SECRET }}              # access a secret
${{ env.AWS_REGION }}                 # environment variable
${{ github.actor }}                   # who triggered the run
${{ steps.plan.outputs.stdout }}      # output from a previous step
```

---

## Manual Trigger & Approvals

**Run a deployment manually:** GitHub → Actions → "Terraform CD (Deploy)" → Run workflow

**Require approval before deploy:** Settings → Environments → `production` → check "Required reviewers"

---

## Monitoring

Add status badges to your README:
```markdown
![CI](https://github.com/Viren1993-web/aws-infra-automation/actions/workflows/terraform-ci.yml/badge.svg)
![CD](https://github.com/Viren1993-web/aws-infra-automation/actions/workflows/terraform-cd.yml/badge.svg)
```

View runs: Repo → **Actions** tab → click any run for logs

Using GitHub CLI:
```bash
gh run list                   # list recent runs
gh run view <run-id>          # details of a specific run
gh run watch                  # live-watch a running workflow
gh workflow run terraform-cd.yml   # trigger CD manually
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Workflow doesn't trigger | Check file is in `.github/workflows/`, YAML is valid, trigger conditions match |
| OIDC credentials fail | See [OIDC Setup](OIDC_SETUP.md) — verify provider, role trust policy, and `AWS_ACCOUNT_ID` |
| Terraform fails | Check state, resource conflicts, IAM permissions ([IAM Policy Reference](IAM_POLICY_REFERENCE.md)) |
| Want to debug | Add `ACTIONS_STEP_DEBUG` secret with value `true` for verbose logs |

---

## Coming from Bitbucket?

| Bitbucket Pipelines | GitHub Actions |
|---------------------|----------------|
| `bitbucket-pipelines.yml` (root) | `.github/workflows/*.yml` |
| `pipelines:` section | `on:` section |
| `parallel:` keyword | Jobs run parallel by default |
| `$VARIABLE` | `${{ env.VARIABLE }}` or `$VARIABLE` |
| Repository Variables | Repository Secrets |
| Pipes | Actions (massive marketplace) |

---

## Best Practices

1. **Separate CI and CD** — validate before you deploy
2. **Use OIDC** — no long-lived credentials
3. **Scope triggers with `paths:`** — only run when relevant files change
4. **Require approval** for production deployments
5. **Post plan on PRs** — reviewers see exactly what changes
6. **Add status badges** — visibility at a glance
