# 🔄 GitHub Actions & Dependabot Configuration

This directory contains the GitHub Actions workflows and Dependabot configuration for the `@home` infrastructure repository.

## 📁 Structure

```
.github/
├── 📄 README.md                           # This documentation
├── 📄 dependabot.yml                      # Dependabot configuration
└── 📁 workflows/                          # GitHub Actions workflows
    ├── 📄 dependabot-self-hosted.yml      # Dependabot validation workflow
    └── 📄 setup-self-hosted-runners.yml   # Runner setup and validation
```

## 🔄 Dependabot Configuration

The `dependabot.yml` file configures automated dependency updates for:

- **📦 Go Dependencies** (`/pulumi`) - Pulumi infrastructure code
- **🐳 Docker Dependencies** - Container configurations
- **📋 GitHub Actions** - CI/CD workflow dependencies
- **🏗️ Flux Dependencies** - GitOps configurations
- **🔧 Script Dependencies** - Automation tools

### 🏷️ Self-Hosted Runner Labels

All Dependabot PRs are configured to use self-hosted runners with the following labels:
- `self-hosted` - Identifies self-hosted runners
- `linux` - Operating system requirement
- `x64` - Architecture requirement
- `dependabot` - Specific label for Dependabot operations

## 🚀 Workflows

### 1. Dependabot Self-Hosted Validation (`dependabot-self-hosted.yml`)

This workflow automatically runs when Dependabot creates or updates a pull request:

**Features:**
- ✅ **Automatic Detection** - Identifies Dependabot PRs
- 🧪 **Multi-Component Testing** - Tests Pulumi, Flux, Docker, and scripts
- 🔒 **Security Scanning** - Runs Trivy security scans
- 📊 **Impact Analysis** - Analyzes dependency changes
- 🤖 **Auto-merge** - Automatically merges minor updates

**Matrix Testing:**
- `pulumi` - Go modules and Pulumi compilation
- `flux` - GitOps manifest validation
- `docker` - Container build validation
- `scripts` - Makefile and script validation

### 2. Self-Hosted Runner Setup (`setup-self-hosted-runners.yml`)

This workflow validates and configures self-hosted runners:

**Features:**
- 🔍 **Runner Validation** - Checks system information and tools
- 🔧 **Tool Verification** - Validates required tools (Docker, kubectl, Go, Pulumi, Flux)
- 🏷️ **Label Management** - Ensures proper runner labeling
- 🔒 **Security Checks** - Validates security configuration
- 📋 **Setup Instructions** - Generates runner setup documentation

## 🛠️ Setup Instructions

### 1. Configure Self-Hosted Runner

```bash
# Create runner directory
mkdir actions-runner && cd actions-runner

# Download runner package
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract installer
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure runner with labels
./config.sh --url https://github.com/brunovlucena/home \
  --token $RUNNER_TOKEN \
  --labels "self-hosted,linux,x64,dependabot" \
  --name "studio-runner"

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

### 2. Required Tools

Ensure the self-hosted runner has the following tools installed:

- **Docker** - For container operations
- **kubectl** - For Kubernetes operations
- **Go** (1.21+) - For Pulumi compilation
- **Pulumi CLI** - For infrastructure operations
- **Flux CLI** - For GitOps operations

### 3. Environment Variables

Set the following environment variables on the runner:

```bash
# GitHub token for registry access
export GITHUB_TOKEN="your_github_token"

# Cloudflare token for DNS management
export CLOUDFLARE_TOKEN="your_cloudflare_token"

# Pulumi access token
export PULUMI_ACCESS_TOKEN="your_pulumi_token"
```

## 🔒 Security Considerations

### Self-Hosted Runner Security

- **Isolation** - Runner should be isolated from production systems
- **Access Control** - Limit network access and file system permissions
- **Token Management** - Use least-privilege tokens
- **Regular Updates** - Keep runner and tools updated
- **Monitoring** - Monitor runner activity and logs

### Dependabot Security

- **Automated Scanning** - All PRs are scanned with Trivy
- **Dependency Validation** - Go modules are verified
- **Container Scanning** - Docker images are security scanned
- **Auto-merge Rules** - Only minor updates are auto-merged

## 📊 Monitoring

### Runner Health

Monitor runner health through:
- GitHub Actions runner status page
- Workflow execution logs
- System resource usage
- Tool availability checks

### Dependabot Activity

Track Dependabot activity through:
- Pull request notifications
- Security alerts
- Dependency update reports
- Auto-merge logs

## 🐛 Troubleshooting

### Common Issues

1. **Runner Offline**
   ```bash
   # Check runner service status
   sudo ./svc.sh status
   
   # Restart runner service
   sudo ./svc.sh restart
   ```

2. **Missing Tools**
   ```bash
   # Install required tools
   sudo apt update
   sudo apt install docker.io kubectl golang-go
   
   # Install Pulumi
   curl -fsSL https://get.pulumi.com | sh
   
   # Install Flux
   curl -s https://fluxcd.io/install.sh | sudo bash
   ```

3. **Permission Issues**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   
   # Configure kubectl access
   mkdir -p ~/.kube
   # Copy kubeconfig file
   ```

### Debug Commands

```bash
# Check runner logs
sudo journalctl -u actions.runner.* -f

# Validate runner configuration
./run.sh --check

# Test workflow manually
gh workflow run "Setup Self-Hosted Runners" --ref main
```

## 📈 Best Practices

1. **Regular Maintenance**
   - Update runner software monthly
   - Rotate access tokens quarterly
   - Monitor disk space and memory usage

2. **Security Updates**
   - Enable automatic security updates
   - Regularly scan for vulnerabilities
   - Keep dependencies updated

3. **Performance Optimization**
   - Use SSD storage for better I/O
   - Allocate sufficient memory (8GB+)
   - Monitor CPU usage during builds

4. **Backup and Recovery**
   - Backup runner configuration
   - Document setup procedures
   - Test disaster recovery procedures

---

**🔗 Related Documentation:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
