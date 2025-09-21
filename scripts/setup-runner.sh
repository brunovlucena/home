#!/bin/bash

# 🏷️ Self-Hosted Runner Setup Script for @home Infrastructure
#
# This script helps set up a self-hosted GitHub Actions runner
# with the proper labels for Dependabot operations.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RUNNER_NAME="studio-runner"
RUNNER_LABELS="self-hosted,linux,x64,dependabot"
RUNNER_WORK_DIR="_work"
REPO_URL="https://github.com/brunovlucena/home"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is designed for Linux systems"
        exit 1
    fi
    
    # Check required commands
    local missing_commands=()
    
    if ! command_exists curl; then
        missing_commands+=("curl")
    fi
    
    if ! command_exists tar; then
        missing_commands+=("tar")
    fi
    
    if ! command_exists sudo; then
        missing_commands+=("sudo")
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_status "Please install them and run the script again"
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Function to get runner token
get_runner_token() {
    print_status "Getting runner registration token..."
    
    if [[ -z "${RUNNER_TOKEN:-}" ]]; then
        print_warning "RUNNER_TOKEN environment variable not set"
        print_status "Please set it with: export RUNNER_TOKEN=your_token_here"
        print_status "You can get the token from: https://github.com/brunovlucena/home/settings/actions/runners"
        exit 1
    fi
    
    print_success "Runner token found"
}

# Function to download and setup runner
setup_runner() {
    print_status "Setting up GitHub Actions runner..."
    
    # Create runner directory
    local runner_dir="actions-runner"
    if [[ -d "$runner_dir" ]]; then
        print_warning "Runner directory already exists. Removing it..."
        rm -rf "$runner_dir"
    fi
    
    mkdir -p "$runner_dir"
    cd "$runner_dir"
    
    # Download runner package
    local runner_version="2.311.0"
    local runner_package="actions-runner-linux-x64-${runner_version}.tar.gz"
    
    print_status "Downloading runner package (v${runner_version})..."
    curl -o "$runner_package" -L \
        "https://github.com/actions/runner/releases/download/v${runner_version}/${runner_package}"
    
    # Extract package
    print_status "Extracting runner package..."
    tar xzf "$runner_package"
    
    # Configure runner
    print_status "Configuring runner..."
    print_status "Runner name: $RUNNER_NAME"
    print_status "Runner labels: $RUNNER_LABELS"
    print_status "Repository: $REPO_URL"
    
    ./config.sh \
        --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --labels "$RUNNER_LABELS" \
        --name "$RUNNER_NAME" \
        --work "$RUNNER_WORK_DIR" \
        --replace \
        --unattended
    
    print_success "Runner configured successfully"
}

# Function to install runner as service
install_service() {
    print_status "Installing runner as system service..."
    
    # Check if already installed
    if systemctl is-active --quiet "actions.runner.${REPO_URL#https://github.com/}__${RUNNER_NAME}" 2>/dev/null; then
        print_warning "Runner service already exists and is running"
        return 0
    fi
    
    # Install service
    sudo ./svc.sh install
    
    # Start service
    sudo ./svc.sh start
    
    print_success "Runner service installed and started"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying runner installation..."
    
    # Check service status
    local service_name="actions.runner.${REPO_URL#https://github.com/}__${RUNNER_NAME}"
    if systemctl is-active --quiet "$service_name"; then
        print_success "Runner service is running"
    else
        print_error "Runner service is not running"
        return 1
    fi
    
    # Check runner status
    if [[ -f ".runner" ]]; then
        print_success "Runner configuration file exists"
    else
        print_error "Runner configuration file not found"
        return 1
    fi
    
    print_success "Runner installation verified successfully"
}

# Function to show next steps
show_next_steps() {
    print_success "🎉 Runner setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Check runner status in GitHub: https://github.com/brunovlucena/home/settings/actions/runners"
    echo "2. Test the runner by running a workflow"
    echo "3. Monitor runner logs: sudo journalctl -u actions.runner.* -f"
    echo
    print_status "Useful commands:"
    echo "- Stop runner: sudo ./svc.sh stop"
    echo "- Start runner: sudo ./svc.sh start"
    echo "- Uninstall runner: sudo ./svc.sh uninstall"
    echo "- Check status: sudo ./svc.sh status"
    echo
    print_status "Runner details:"
    echo "- Name: $RUNNER_NAME"
    echo "- Labels: $RUNNER_LABELS"
    echo "- Work directory: $RUNNER_WORK_DIR"
    echo "- Repository: $REPO_URL"
}

# Function to show help
show_help() {
    echo "🏷️ Self-Hosted Runner Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -n, --name NAME        Set runner name (default: $RUNNER_NAME)"
    echo "  -l, --labels LABELS    Set runner labels (default: $RUNNER_LABELS)"
    echo "  -w, --work-dir DIR     Set work directory (default: $RUNNER_WORK_DIR)"
    echo "  -h, --help            Show this help message"
    echo
    echo "Environment variables:"
    echo "  RUNNER_TOKEN          GitHub runner registration token (required)"
    echo
    echo "Example:"
    echo "  export RUNNER_TOKEN=your_token_here"
    echo "  $0 --name my-runner --labels 'self-hosted,linux,x64,dependabot'"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            RUNNER_NAME="$2"
            shift 2
            ;;
        -l|--labels)
            RUNNER_LABELS="$2"
            shift 2
            ;;
        -w|--work-dir)
            RUNNER_WORK_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "🏷️ Starting self-hosted runner setup for @home infrastructure"
    echo
    
    check_requirements
    get_runner_token
    setup_runner
    install_service
    verify_installation
    show_next_steps
}

# Run main function
main "$@"
