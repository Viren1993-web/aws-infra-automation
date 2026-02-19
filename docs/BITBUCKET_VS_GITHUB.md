# Bitbucket Pipelines → GitHub Actions: Quick Reference

## 📋 Side-by-Side Comparison

### File Location & Structure

**Bitbucket:**
```yaml
# bitbucket-pipelines.yml (root of repo)
pipelines:
  default:
    - step:
        name: Build
        script:
          - echo "Hello"
```

**GitHub Actions:**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello"
```

---

### Triggers

**Bitbucket:**
```yaml
pipelines:
  branches:
    main:
      - step: ...
  
  pull-requests:
    '**':
      - step: ...
  
  custom:
    deploy-prod:
      - step: ...
```

**GitHub Actions:**
```yaml
on:
  push:
    branches: [main]
  
  pull_request:
    branches: [main]
  
  workflow_dispatch:  # Manual trigger
```

---

### Environment Variables

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        script:
          - echo $MY_VAR
          - export BUILD_ID=123
definitions:
  variables:
    - name: MY_VAR
      default: "value"
```

**GitHub Actions:**
```yaml
env:
  MY_VAR: "value"

jobs:
  build:
    steps:
      - run: echo $MY_VAR
      - run: echo "BUILD_ID=123" >> $GITHUB_ENV
```

---

### Secrets

**Bitbucket:**
```yaml
# Access via: Repository Settings → Variables
pipelines:
  default:
    - step:
        script:
          - echo $AWS_KEY  # Secured variable
```

**GitHub Actions:**
```yaml
# Add via: Settings → Secrets → Actions
jobs:
  deploy:
    steps:
      - run: echo ${{ secrets.AWS_KEY }}
```

---

### Parallel Jobs

**Bitbucket:**
```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Test 1
            script: [...]
        - step:
            name: Test 2
            script: [...]
```

**GitHub Actions:**
```yaml
# Parallel by default!
jobs:
  test1:
    steps: [...]
  
  test2:
    steps: [...]
```

---

### Sequential Dependencies

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        name: Build
        script: [...]
    - step:
        name: Deploy
        script: [...]  # Runs after Build
```

**GitHub Actions:**
```yaml
jobs:
  build:
    steps: [...]
  
  deploy:
    needs: build  # Waits for build
    steps: [...]
```

---

### Artifacts

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        name: Build
        script:
          - make build
        artifacts:
          - dist/**
    - step:
        name: Deploy
        script:
          - deploy dist/
```

**GitHub Actions:**
```yaml
jobs:
  build:
    steps:
      - run: make build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
  
  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
      - run: deploy dist/
```

---

### Caching

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        caches:
          - node
          - pip
        script:
          - npm install
definitions:
  caches:
    pip: ~/.cache/pip
```

**GitHub Actions:**
```yaml
jobs:
  build:
    steps:
      - uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
      - run: pip install -r requirements.txt
```

---

### Docker

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        image: python:3.11
        script:
          - python --version
```

**GitHub Actions:**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: python:3.11
    steps:
      - run: python --version
```

---

### Services (e.g., Database)

**Bitbucket:**
```yaml
pipelines:
  default:
    - step:
        services:
          - postgres
        script:
          - psql -h localhost
definitions:
  services:
    postgres:
      image: postgres:14
```

**GitHub Actions:**
```yaml
jobs:
  test:
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
    steps:
      - run: psql -h localhost
```

---

### Conditional Execution

**Bitbucket:**
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production
          script:
            - if [ "$BITBUCKET_BRANCH" == "main" ]; then deploy; fi
```

**GitHub Actions:**
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: deploy
```

---

### Clone/Checkout

**Bitbucket:**
```yaml
# Automatic by default
pipelines:
  default:
    - step:
        clone:
          depth: full  # or shallow
        script:
          - git log
```

**GitHub Actions:**
```yaml
# Must be explicit
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # full history
```

---

### Pipes vs Actions

**Bitbucket (Pipes):**
```yaml
pipelines:
  default:
    - step:
        script:
          - pipe: atlassian/aws-s3-deploy:1.1.0
            variables:
              AWS_ACCESS_KEY_ID: $AWS_KEY
              S3_BUCKET: 'my-bucket'
```

**GitHub Actions:**
```yaml
jobs:
  deploy:
    steps:
      - uses: jakejarvis/s3-sync-action@master
        with:
          args: --follow-symlinks --delete
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_KEY }}
          AWS_S3_BUCKET: 'my-bucket'
```

---

### Manual Approval

**Bitbucket:**
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy
          deployment: production  # Requires manual trigger
          script: [...]
```

**GitHub Actions:**
```yaml
# In Settings → Environments → production
# Enable "Required reviewers"

jobs:
  deploy:
    environment: production  # Waits for approval
    steps: [...]
```

---

### Status Badges

**Bitbucket:**
```markdown
[![Build Status](https://img.shields.io/bitbucket/pipelines/username/repo)](https://bitbucket.org/username/repo/addon/pipelines/home)
```

**GitHub Actions:**
```markdown
[![CI](https://github.com/username/repo/actions/workflows/ci.yml/badge.svg)](https://github.com/username/repo/actions)
```

---

## 🎯 Key Differences Summary

| Feature | Bitbucket | GitHub Actions |
|---------|-----------|----------------|
| **Parallelism** | Explicit `parallel:` | Parallel by default |
| **Checkout** | Automatic | Needs `actions/checkout` |
| **Docker** | Default environment | Need `container:` or `runs-on` |
| **Syntax** | More compact | More verbose but flexible |
| **Marketplace** | Limited pipes | Huge actions marketplace |
| **Free minutes** | 50 min/month (free tier) | 2,000 min/month |
| **Reusable** | Can reference pipelines | Reusable workflows |

## 📖 Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Migrating from Bitbucket](https://docs.github.com/en/actions/migrating-to-github-actions/migrating-from-bitbucket-pipelines-to-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
