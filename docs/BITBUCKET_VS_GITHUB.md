# Bitbucket Pipelines → GitHub Actions: Quick Reference

> If you're coming from Bitbucket, this maps every concept to its GitHub Actions equivalent.

---

## Concept Mapping

| Concept | Bitbucket Pipelines | GitHub Actions |
|---------|---------------------|----------------|
| **Config file** | `bitbucket-pipelines.yml` (root) | `.github/workflows/*.yml` |
| **Triggers** | `pipelines: branches: / pull-requests: / custom:` | `on: push / pull_request / workflow_dispatch` |
| **Jobs** | `pipelines: default: - step:` | `jobs: build: steps:` |
| **Parallelism** | Explicit `parallel:` keyword | Jobs run parallel **by default** |
| **Sequential** | Steps are sequential by default | Use `needs: [job1]` for dependencies |
| **Env vars** | `$VARIABLE` + `definitions: variables:` | `${{ env.VAR }}` or `$VAR` + `env:` block |
| **Secrets** | Repo Settings → Variables (secured) | Repo Settings → Secrets → Actions |
| **Docker image** | `image: python:3.11` on step | `container: image: python:3.11` on job |
| **Cache** | `caches: - node` + `definitions: caches:` | `actions/cache@v4` with key/path |
| **Artifacts** | `artifacts: - dist/**` on step | `actions/upload-artifact@v4` + `download-artifact@v4` |
| **Services** | `services: - postgres` + `definitions:` | `services: postgres:` on job with `ports:` |
| **Checkout** | Automatic | Explicit: `uses: actions/checkout@v4` |
| **Reusable** | Reference other pipelines | Reusable workflows + Actions marketplace |
| **Pipes / Actions** | `pipe: atlassian/aws-s3-deploy:1.1.0` | `uses: jakejarvis/s3-sync-action@master` |
| **Manual trigger** | `custom:` pipeline | `workflow_dispatch:` event |
| **Approval** | `deployment: production` | `environment: production` + required reviewers |
| **Conditionals** | `if [ "$BITBUCKET_BRANCH" == "main" ]` | `if: github.ref == 'refs/heads/main'` |
| **Status badge** | `img.shields.io/bitbucket/pipelines/...` | `github.com/.../actions/workflows/ci.yml/badge.svg` |
| **Free minutes** | 50 min/month | 2,000 min/month |

---

## Side-by-Side: Minimal Example

**Bitbucket:**
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          caches: [node]
          script:
            - npm install
            - npm run deploy
```

**GitHub Actions:**
```yaml
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
      - run: npm install && npm run deploy
```

Key differences: GitHub needs explicit checkout, cache is an action, and `runs-on` replaces Bitbucket's default Docker environment.

---

## Resources

- [Official Migration Guide](https://docs.github.com/en/actions/migrating-to-github-actions/migrating-from-bitbucket-pipelines-to-github-actions)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
