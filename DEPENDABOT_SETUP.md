# 🤖 Dependabot Self-Hosted Runner Setup Complete

## ✅ What's Been Implemented

### 1. 📄 Dependabot Configuration (`.github/dependabot.yml`)
- **Go Dependencies** - Pulumi infrastructure code updates
- **Docker Dependencies** - Container configuration updates
- **GitHub Actions** - CI/CD workflow dependency updates
- **Flux Dependencies** - GitOps configuration updates
- **Script Dependencies** - Automation tool updates

### 2. 🔄 GitHub Actions Workflows

#### `dependabot-self-hosted.yml`
- **Automatic Dependabot Detection** - Identifies and processes Dependabot PRs
- **Multi-Component Testing** - Tests Pulumi, Flux, Docker, and scripts
- **Security Scanning** - Runs Trivy security scans on all changes
- **Impact Analysis** - Analyzes dependency change impact
- **Auto-merge** - Automatically merges minor updates after validation

#### `setup-self-hosted-runners.yml`
- **Runner Validation** - Checks system information and required tools
- **Tool Verification** - Validates Docker, kubectl, Go, Pulumi, Flux
- **Security Checks** - Ensures proper security configuration
- **Setup Instructions** - Generates runner setup documentation

### 3. 🏷️ Self-Hosted Runner Labels
All workflows are configured to use runners with these labels:
- `self-hosted` - Identifies self-hosted runners
- `linux` - Operating system requirement
- `x64` - Architecture requirement
- `dependabot` - Specific label for Dependabot operations

### 4. 📋 Documentation
- **`.github/README.md`** - Comprehensive setup and usage guide
- **`scripts/setup-runner.sh`** - Automated runner setup script
- **Updated main README** - Added Dependabot section

## 🚀 Next Steps

### 1. Set Up Self-Hosted Runner

```bash
# Get runner token from GitHub
# Go to: https://github.com/brunovlucena/home/settings/actions/runners

# Set environment variable
export RUNNER_TOKEN="your_runner_token_here"

# Run setup script
cd /Users/brunolucena/workspace/bruno/repos/home
./scripts/setup-runner.sh
```

### 2. Verify Runner Setup

```bash
# Check runner status in GitHub
# Visit: https://github.com/brunovlucena/home/settings/actions/runners

# Test runner with manual workflow
# Go to: https://github.com/brunovlucena/home/actions/workflows/setup-self-hosted-runners.yml
# Click "Run workflow"
```

### 3. Enable Dependabot

Dependabot will automatically start creating PRs once the runner is set up. You can also manually trigger it:

```bash
# Go to GitHub repository settings
# Navigate to: Security → Dependabot alerts
# Enable Dependabot alerts and security updates
```

## 🔧 Configuration Details

### Dependabot Schedule
- **Monday 9 AM BRT** - Go dependencies (Pulumi)
- **Tuesday 9 AM BRT** - Docker dependencies
- **Wednesday 9 AM BRT** - GitHub Actions
- **Thursday 9 AM BRT** - Flux dependencies
- **Friday 9 AM BRT** - Script dependencies

### Auto-merge Rules
- ✅ **Minor updates** - Automatically merged after validation
- ⚠️ **Major updates** - Require manual review
- 🔒 **Security updates** - Always require review

### Security Features
- **Trivy Scanning** - All PRs are security scanned
- **Dependency Verification** - Go modules are verified
- **Container Scanning** - Docker images are scanned
- **Impact Analysis** - Changes are analyzed for impact

## 📊 Monitoring

### Runner Health
- Monitor through GitHub Actions runner status page
- Check workflow execution logs
- Monitor system resource usage

### Dependabot Activity
- Track through pull request notifications
- Monitor security alerts
- Review dependency update reports

## 🐛 Troubleshooting

### Common Issues

1. **Runner Offline**
   ```bash
   sudo ./svc.sh restart
   ```

2. **Missing Tools**
   ```bash
   # Install required tools
   sudo apt update
   sudo apt install docker.io kubectl golang-go
   curl -fsSL https://get.pulumi.com | sh
   curl -s https://fluxcd.io/install.sh | sudo bash
   ```

3. **Permission Issues**
   ```bash
   sudo usermod -aG docker $USER
   ```

## 🎉 Benefits

- **🔒 Enhanced Security** - All updates run on your own infrastructure
- **⚡ Better Performance** - No queue time on GitHub-hosted runners
- **🎯 Custom Environment** - Access to your specific tools and configurations
- **📊 Full Control** - Complete visibility and control over the update process
- **🤖 Automation** - Hands-free dependency management with validation

---

**🎯 The Dependabot self-hosted runner setup is now complete and ready to use!**
