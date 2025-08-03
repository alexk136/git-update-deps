#!/bin/bash

# Script to update git-based Python dependencies
# This script forces reinstallation of packages installed from git repositories

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if virtual environment is activated
check_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        print_message $RED "❌ Virtual environment is not activated!"
        print_message $YELLOW "Please activate your virtual environment first:"
        print_message $BLUE "source .venv/bin/activate"
        exit 1
    fi
    print_message $GREEN "✅ Virtual environment detected: $VIRTUAL_ENV"
}

# Function to update a git-based package
update_git_package() {
    local package_name=$1
    local git_url=$2
    
    print_message $BLUE "🔄 Updating $package_name from $git_url"
    
    # Uninstall the package
    print_message $YELLOW "  Uninstalling $package_name..."
    pip uninstall -y "$package_name" || true
    
    # Clear pip cache for this package
    print_message $YELLOW "  Clearing pip cache..."
    pip cache remove "$package_name" || true
    
    # Reinstall from git with force upgrade
    print_message $YELLOW "  Installing latest version from git..."
    pip install --force-reinstall --no-cache-dir --no-deps "$git_url"
    
    print_message $GREEN "✅ Successfully updated $package_name"
}

# Function to register this script globally
register_global() {
    echo "🔧 Registering update-git-deps command globally..."
    
    # Get the absolute path to the script
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    # Check write permissions for /usr/local/bin
    if [ -w /usr/local/bin ]; then
        ln -sf "$SCRIPT_PATH" /usr/local/bin/update-git-deps
        print_message $GREEN "✅ update-git-deps command successfully registered!"
        print_message $BLUE "💡 Now you can use 'update-git-deps' from any folder"
    else
        print_message $YELLOW "🔐 Administrator rights are required to register the command:"
        echo "sudo ln -sf '$SCRIPT_PATH' /usr/local/bin/update-git-deps"
        echo ""
        print_message $YELLOW "Or add this command to your ~/.bashrc:"
        echo "alias update-git-deps='$SCRIPT_PATH'"
    fi
}

# Function to uninstall global command
uninstall_global() {
    local bin_dir="$HOME/.local/bin"
    local global_name="update-git-deps"
    
    if rm -f "$bin_dir/$global_name" 2>/dev/null; then
        print_message $GREEN "✅ Successfully uninstalled global command: $global_name"
    else
        print_message $YELLOW "⚠️ Global command not found or already removed"
    fi
}

# Main function
main() {
    print_message $BLUE "🚀 Starting git dependencies update..."
    
    # Check if requirements.txt exists in current directory
    if [[ ! -f "requirements.txt" ]]; then
        print_message $RED "❌ requirements.txt not found in current directory"
        print_message $YELLOW "Please run this command from a directory containing requirements.txt"
        exit 1
    fi
    
    # Check virtual environment
    check_venv
    
    # Parse requirements.txt for dependencies
dependencies=$(grep -v "^#" requirements.txt | tr -d '\r' | grep -v "^$")

    # Update each dependency
    while IFS= read -r dep; do
        # Skip empty lines and comments
        [[ -z "$dep" || "$dep" =~ ^[[:space:]]*# ]] && continue
        
        if [[ $dep == *"git+ssh://"* ]]; then
            # Extract package name and git URL for @ syntax
            if [[ $dep == *" @ "* ]]; then
                package_name=$(echo "$dep" | cut -d' ' -f1)
                git_url=$(echo "$dep" | sed 's/.* @ //')
            else
                # Handle direct git+ssh URLs
                package_name=$(basename "$dep" .git | sed 's/.*\///')
                git_url="$dep"
            fi
            update_git_package "$package_name" "$git_url"
        else
            print_message $BLUE "🔄 Updating $dep..."
            pip install --upgrade "$dep"
            print_message $GREEN "✅ Successfully updated $dep"
        fi
        echo  # Empty line for readability
    done <<< "$dependencies"

    # Show installed packages
    print_message $BLUE "📦 Current installed packages:"
    pip list
    
    print_message $GREEN "🎉 All git dependencies updated successfully!"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Update git-based Python dependencies by forcing reinstallation"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  --register       Register this script as global command 'update-git-deps'"
    echo "  --uninstall      Remove global command 'update-git-deps'"
    echo ""
    echo "Before running this script:"
    echo "1. Make sure your virtual environment is activated"
    echo "2. Ensure you have SSH access to the git repositories"
    echo "3. Run from directory containing requirements.txt"
    echo ""
    echo "Example:"
    echo "  # Register globally"
    echo "  ./update_git_deps.sh --register"
    echo ""
    echo "  # Use after registration"
    echo "  cd /path/to/your/project"
    echo "  source .venv/bin/activate"
    echo "  update-git-deps"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --register)
        register_global
        exit 0
        ;;
    --uninstall)
        uninstall_global
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_message $RED "❌ Unknown option: $1"
        show_help
        exit 1
        ;;
esac
