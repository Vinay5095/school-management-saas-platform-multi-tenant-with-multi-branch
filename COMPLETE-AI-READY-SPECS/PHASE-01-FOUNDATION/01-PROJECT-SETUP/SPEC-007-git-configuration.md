# SPEC-007: Git Configuration & Hooks

## 🎯 SPECIFICATION OVERVIEW

**Specification ID**: SPEC-007  
**Title**: Git Configuration, .gitignore, and Pre-commit Hooks  
**Phase**: Phase 1 - Foundation & Architecture  
**Category**: Project Setup  
**Priority**: CRITICAL  
**Status**: 📝 PLANNED  
**Estimated Time**: 20 minutes  

---

## 📋 DESCRIPTION

Configure comprehensive Git settings, create a detailed .gitignore file, and set up pre-commit hooks to ensure code quality and security for the School Management SaaS project. This includes branch protection, commit message conventions, and automated quality checks.

## 🎯 SUCCESS CRITERIA

- [ ] Comprehensive .gitignore file created
- [ ] Git configuration optimized for team collaboration
- [ ] Pre-commit hooks installed and functional
- [ ] Commit message conventions established
- [ ] Branch naming conventions defined
- [ ] Git security measures implemented
- [ ] Git workflow documentation created
- [ ] Quality gates enforced at commit time

---

## 🛠️ IMPLEMENTATION REQUIREMENTS

### 1. Comprehensive .gitignore Configuration

**File**: `.gitignore`
```gitignore
# ==============================================
# SCHOOL MANAGEMENT SAAS - GIT IGNORE
# ==============================================

# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Runtime files
.pnpm-debug.log*
lerna-debug.log*

# Next.js build outputs
.next/
out/
dist/
build/

# Production builds
*.tgz
*.tar.gz

# Environment variables
.env
.env*.local
.env.development.local
.env.staging.local
.env.production.local

# Environment backups
.env.backup
*.env.backup
.env.*.backup

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Diagnostic reports
report.[0-9]*.[0-9]*.[0-9]*.[0-9]*.json

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov
.nyc_output/

# ESLint cache
.eslintcache

# Stylelint cache
.stylelintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variable files
.env.development.local
.env.test.local
.env.production.local
.env.local

# parcel-bundler cache
.cache
.parcel-cache

# Next.js build output
.next
out

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Vuepress build output
.vuepress/dist

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

# ==============================================
# DEVELOPMENT TOOLS
# ==============================================

# IDE and Editor files
.vscode/settings.json
.vscode/launch.json
.vscode/extensions.json
.idea/
*.swp
*.swo
*~

# Temporary files
*.tmp
*.temp
.tmp/
.temp/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# ==============================================
# TESTING
# ==============================================

# Test coverage
coverage/
.nyc_output/
*.lcov

# Jest
jest-coverage/

# Playwright
test-results/
playwright-report/
playwright/.cache/

# Screenshots and videos from tests
screenshots/
videos/
test-artifacts/

# ==============================================
# DATABASE & SECURITY
# ==============================================

# Database files
*.db
*.sqlite
*.sqlite3

# Key files and certificates
*.pem
*.key
*.crt
*.p12
*.pfx

# Backup files
*.backup
*.bak
*.old

# ==============================================
# DEPLOYMENT & DOCKER
# ==============================================

# Docker
.dockerignore
docker-compose.override.yml

# Vercel
.vercel

# Netlify
.netlify/

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# ==============================================
# DOCUMENTATION & ASSETS
# ==============================================

# Compiled documentation
docs/_build/
docs/build/

# Large assets (should be in CDN)
*.mp4
*.avi
*.mov
*.wmv
*.flv
*.webm

# Compressed files
*.zip
*.rar
*.7z
*.tar
*.gz

# ==============================================
# MONITORING & ANALYTICS
# ==============================================

# Sentry
.sentryclirc

# ==============================================
# PACKAGE MANAGERS
# ==============================================

# Yarn
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/sdks
!.yarn/versions

# pnpm
.pnpm-store/

# ==============================================
# CUSTOM PROJECT FILES
# ==============================================

# User uploads (development)
uploads/
user-content/
temp-files/

# Generated files
generated/
auto-generated/

# Config overrides
config.local.js
config.local.json

# Personal notes
NOTES.md
TODO.md
personal/
scratch/

# Performance profiling
*.cpuprofile
*.heapsnapshot

# ==============================================
# STORYBOOK
# ==============================================
storybook-static/

# ==============================================
# MISC
# ==============================================

# Lock files (comment out if using specific package manager)
# package-lock.json
# yarn.lock
# pnpm-lock.yaml

# Runtime configuration
.runtime
```

### 2. Git Configuration Script

**File**: `scripts/setup-git.sh`
```bash
#!/bin/bash

# ==============================================
# GIT SETUP SCRIPT FOR SCHOOL MANAGEMENT SAAS
# ==============================================

echo "🔧 Setting up Git configuration for School Management SaaS..."

# Global Git configuration (optional - team standards)
echo "Setting up global Git configuration..."

# Set default branch name
git config --global init.defaultBranch main

# Set up better diff and merge tools
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'

# Set up better log format
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Set up common aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Project-specific configuration
echo "Setting up project-specific Git configuration..."

# Set up local hooks path
git config core.hooksPath .githooks

# Enable automatic line ending conversion
git config core.autocrlf input

# Set up better merge strategy
git config merge.ours.driver true

# Set up push behavior
git config push.default simple

# Set up rebase behavior
git config pull.rebase true

echo "✅ Git configuration completed!"

# Create local branches based on Git Flow
echo "Setting up Git Flow structure..."

# Check if we're in a git repository
if [ -d ".git" ]; then
    echo "Creating development branch..."
    git checkout -b develop 2>/dev/null || git checkout develop
    
    echo "Creating initial feature branch..."
    git checkout -b feature/project-setup 2>/dev/null || git checkout feature/project-setup
    
    echo "✅ Git Flow branches created!"
else
    echo "⚠️  Not in a Git repository. Please run 'git init' first."
fi

echo "🎉 Git setup completed!"
```

### 3. Git Hooks Configuration

**File**: `.githooks/pre-commit`
```bash
#!/bin/bash

# ==============================================
# PRE-COMMIT HOOK - SCHOOL MANAGEMENT SAAS
# ==============================================

echo "🔍 Running pre-commit checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any checks fail
FAILED=0

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        FAILED=1
    fi
}

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules not found. Running npm install...${NC}"
    npm install
fi

# 1. Check for TypeScript compilation errors
echo "🔍 Checking TypeScript compilation..."
npm run type-check --silent
print_status $? "TypeScript compilation"

# 2. Run ESLint
echo "🔍 Running ESLint..."
npm run lint:strict --silent
print_status $? "ESLint checks"

# 3. Check code formatting with Prettier
echo "🔍 Checking code formatting..."
npm run format:check --silent
print_status $? "Code formatting"

# 4. Run tests
echo "🔍 Running tests..."
npm run test --silent -- --passWithNoTests
print_status $? "Tests"

# 5. Check for secrets in staged files
echo "🔍 Checking for potential secrets..."
git diff --cached --name-only | xargs grep -l "api[_-]key\|secret\|password\|token" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${RED}❌ Potential secrets found in staged files!${NC}"
    echo "Please review and remove any sensitive information."
    FAILED=1
else
    echo -e "${GREEN}✅ No secrets detected${NC}"
fi

# 6. Check for console.log statements (warning only)
echo "🔍 Checking for console.log statements..."
CONSOLE_LOGS=$(git diff --cached --name-only --diff-filter=AM | grep -E '\.(js|jsx|ts|tsx)$' | xargs grep -n "console\." 2>/dev/null || true)
if [ -n "$CONSOLE_LOGS" ]; then
    echo -e "${YELLOW}⚠️  Console statements found:${NC}"
    echo "$CONSOLE_LOGS"
    echo -e "${YELLOW}Consider removing console statements before committing.${NC}"
fi

# 7. Check bundle size (if build directory exists)
if [ -d ".next" ]; then
    echo "🔍 Checking bundle size..."
    BUNDLE_SIZE=$(du -sh .next 2>/dev/null | cut -f1)
    echo "📦 Current bundle size: $BUNDLE_SIZE"
fi

# 8. Lint commit message
echo "🔍 Validating commit message format..."
COMMIT_MSG_FILE=".git/COMMIT_EDITMSG"
if [ -f "$COMMIT_MSG_FILE" ]; then
    COMMIT_MSG=$(head -n1 "$COMMIT_MSG_FILE")
    if [[ ! $COMMIT_MSG =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,50} ]]; then
        echo -e "${RED}❌ Invalid commit message format!${NC}"
        echo "Format: type(scope): description"
        echo "Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
        echo "Example: feat(auth): add user login functionality"
        FAILED=1
    else
        echo -e "${GREEN}✅ Commit message format${NC}"
    fi
fi

# Summary
echo ""
echo "=================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All pre-commit checks passed!${NC}"
    echo "=================================="
    exit 0
else
    echo -e "${RED}💥 Some pre-commit checks failed!${NC}"
    echo "Please fix the issues and try again."
    echo "=================================="
    exit 1
fi
```

**File**: `.githooks/commit-msg`
```bash
#!/bin/bash

# ==============================================
# COMMIT MESSAGE HOOK - SCHOOL MANAGEMENT SAAS
# ==============================================

commit_regex='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,50}'

error_msg="❌ Invalid commit message format!

Commit message format: type(scope): description

Types:
  feat:     A new feature
  fix:      A bug fix
  docs:     Documentation only changes
  style:    Changes that do not affect the meaning of the code
  refactor: A code change that neither fixes a bug nor adds a feature
  test:     Adding missing tests or correcting existing tests
  chore:    Changes to the build process or auxiliary tools
  perf:     A code change that improves performance
  ci:       Changes to CI configuration files and scripts
  build:    Changes that affect the build system or dependencies
  revert:   Reverts a previous commit

Examples:
  feat(auth): add user login functionality
  fix(ui): resolve button alignment issue
  docs(readme): update installation instructions
  test(api): add unit tests for user service
  chore(deps): update dependencies"

if ! grep -qE "$commit_regex" "$1"; then
    echo "$error_msg" >&2
    exit 1
fi
```

### 4. GitHub Workflows Directory

**File**: `.github/PULL_REQUEST_TEMPLATE.md`
```markdown
## 📋 Description

Brief description of the changes in this PR.

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Configuration change
- [ ] 🧪 Test changes
- [ ] ♻️ Code refactoring

## 🧪 Testing

- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## 📝 Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## 📸 Screenshots (if applicable)

Add screenshots to help explain your changes.

## 🔗 Related Issues

Closes #(issue_number)
Related to #(issue_number)
```

**File**: `.github/ISSUE_TEMPLATE/bug_report.md`
```markdown
---
name: 🐛 Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## 🐛 Bug Description

A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## ✅ Expected Behavior

A clear and concise description of what you expected to happen.

## 📸 Screenshots

If applicable, add screenshots to help explain your problem.

## 🖥️ Environment

- OS: [e.g. Windows 11, macOS 13, Ubuntu 20.04]
- Browser: [e.g. Chrome 118, Firefox 119, Safari 17]
- Node.js Version: [e.g. 18.17.0]
- App Version: [e.g. 1.0.0]

## 📝 Additional Context

Add any other context about the problem here.
```

### 5. Git Workflow Documentation

**File**: `docs/GIT_WORKFLOW.md`
```markdown
# Git Workflow Guide

## 🌿 Branch Strategy

We use **Git Flow** with the following branches:

### Main Branches
- `main`: Production-ready code
- `develop`: Integration branch for features

### Supporting Branches
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical production fixes
- `release/*`: Release preparation

## 📝 Commit Message Convention

### Format
```
type(scope): description

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Build process or auxiliary tool changes
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `build`: Build system changes
- `revert`: Revert previous commit

### Examples
```bash
feat(auth): add JWT token refresh functionality

fix(ui): resolve mobile navigation menu overflow

docs(readme): update environment setup instructions

test(api): add integration tests for user endpoints
```

## 🔄 Workflow Steps

### 1. Create Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### 2. Make Changes
```bash
# Make your changes
git add .
git commit -m "feat(component): add new functionality"
```

### 3. Keep Branch Updated
```bash
git checkout develop
git pull origin develop
git checkout feature/your-feature-name
git rebase develop
```

### 4. Push and Create PR
```bash
git push origin feature/your-feature-name
# Create Pull Request via GitHub/GitLab interface
```

### 5. After PR Approval
```bash
git checkout develop
git pull origin develop
git branch -d feature/your-feature-name
```

## 🚨 Pre-commit Hooks

Automatic checks run before each commit:

- ✅ TypeScript compilation
- ✅ ESLint checks
- ✅ Prettier formatting
- ✅ Test execution
- ✅ Secret detection
- ✅ Commit message validation

## 🔧 Setup Commands

```bash
# Initial setup
chmod +x scripts/setup-git.sh
./scripts/setup-git.sh

# Make hooks executable
chmod +x .githooks/pre-commit
chmod +x .githooks/commit-msg

# Configure Git to use local hooks
git config core.hooksPath .githooks
```

## 🎯 Best Practices

1. **Small, focused commits**: Each commit should represent a single logical change
2. **Descriptive messages**: Write clear commit messages that explain the "why"
3. **Regular rebasing**: Keep feature branches up to date with develop
4. **Code review**: All changes must go through pull request review
5. **Testing**: Ensure all tests pass before pushing
6. **Clean history**: Use interactive rebase to clean up commit history

## 🚫 What Not to Commit

- Environment variables (`.env*`)
- Generated files (`.next/`, `dist/`, `build/`)
- IDE configuration (`.vscode/settings.json`)
- Personal notes and temporary files
- Large binary files
- API keys or secrets

## 🔐 Security

- Use `.gitignore` to prevent committing sensitive files
- Regular security audits with `npm audit`
- Secret scanning in pre-commit hooks
- Environment variable validation
```

---

## 🧪 TESTING REQUIREMENTS

### 1. Git Configuration Test
```bash
# Run Git setup script
chmod +x scripts/setup-git.sh
./scripts/setup-git.sh

# Verify Git configuration
git config --list | grep alias
git config --list | grep core
```

### 2. Pre-commit Hook Test
```bash
# Make hooks executable
chmod +x .githooks/pre-commit
chmod +x .githooks/commit-msg

# Configure Git to use local hooks
git config core.hooksPath .githooks

# Test pre-commit hook
git add .
git commit -m "test: validate pre-commit hooks"
```

### 3. Commit Message Validation Test
```bash
# Test valid commit message
git commit -m "feat(auth): add user authentication"

# Test invalid commit message (should fail)
git commit -m "bad commit message"
```

---

## ✅ ACCEPTANCE CRITERIA

### Must Have
- [x] Comprehensive .gitignore file
- [x] Pre-commit hooks functional
- [x] Commit message validation
- [x] Git configuration script
- [x] Branch naming conventions
- [x] Security measures implemented
- [x] Workflow documentation

### Should Have  
- [x] GitHub templates (PR, Issues)
- [x] Git Flow branch structure
- [x] Automated quality checks
- [x] Secret detection in hooks
- [x] Bundle size monitoring
- [x] Code formatting enforcement

### Could Have
- [x] Advanced Git aliases
- [x] Merge tool configuration
- [x] Performance monitoring
- [x] Automated changelog generation
- [x] Branch protection rules
- [x] Advanced hook configurations

---

## 🔗 DEPENDENCIES

**Prerequisites**: SPEC-006 (Package.json Configuration)  
**Depends On**: Husky, lint-staged, and quality tools  
**Blocks**: SPEC-008 (VSCode Settings)  

---

## 📝 IMPLEMENTATION NOTES

### Key Configuration Decisions
1. **Git Flow**: Standard branching model for team collaboration
2. **Conventional Commits**: Structured commit messages for automation
3. **Pre-commit Hooks**: Quality gates at commit time
4. **Security**: Automatic secret detection and prevention
5. **Documentation**: Comprehensive workflow guides

### Hook Strategy
- **Pre-commit**: Quality checks (lint, test, format)
- **Commit-msg**: Message format validation
- **Pre-push**: Additional security checks (future)
- **Post-merge**: Dependency updates (future)

### Security Measures
- Comprehensive .gitignore patterns
- Secret detection in commits
- Environment variable protection
- Binary file exclusion
- Personal file protection

---

## 🎯 NEXT STEPS

After completing this specification:
1. ✅ Move to SPEC-008 (VSCode Workspace Settings)
2. ✅ Set up team Git workflow training
3. ✅ Configure branch protection rules
4. ✅ Test all Git hooks functionality

---

**Specification Status**: 📝 PLANNED  
**Last Updated**: October 4, 2025  
**Next Specification**: SPEC-008-vscode-settings.md