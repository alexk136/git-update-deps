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
    # Check if .venv directory exists in current directory
    if [[ ! -d ".venv" ]]; then
        print_message $YELLOW "📦 Local .venv directory not found. Creating..."
        python -m venv .venv
        print_message $GREEN "✅ Created .venv directory"
    fi
    
    # Check if virtual environment is activated
    if [[ -z "$VIRTUAL_ENV" ]]; then
        print_message $YELLOW "🔄 Virtual environment not activated. Activating..."
        # Source the activation script
        source .venv/bin/activate
        print_message $GREEN "✅ Activated .venv environment"
        # Update VIRTUAL_ENV for this script context
        export VIRTUAL_ENV="$(pwd)/.venv"
        export PATH="$VIRTUAL_ENV/bin:$PATH"
    fi
    
    # Check if we're in a local virtual environment (.venv)
    local current_dir="$(pwd)"
    local venv_name="$(basename "$VIRTUAL_ENV")"
    
    # Must be using local .venv environment
    if [[ "$venv_name" == ".venv" || "$VIRTUAL_ENV" == "$current_dir/.venv" || "$VIRTUAL_ENV" == *"/.venv" ]]; then
        print_message $GREEN "✅ Local .venv environment detected: $VIRTUAL_ENV"
    else
        print_message $RED "❌ Must use local .venv environment for updates!"
        print_message $YELLOW "Current environment: $VIRTUAL_ENV"
        print_message $BLUE "Please activate local .venv: source .venv/bin/activate"
        exit 1
    fi
}

# Function to get pip command
get_pip_cmd() {
    local local_pip="$(pwd)/.venv/bin/pip"
    local local_python="$(pwd)/.venv/bin/python"
    
    if [[ -f "$local_pip" ]]; then
        echo "$local_pip"
    else
        # Use local python with global pip module
        echo "$local_python -m pip"
    fi
}

# Function to update a git-based package
update_git_package() {
    local package_name=$1
    local git_url=$2
    
    print_message $BLUE "🔄 Updating $package_name from $git_url"
    
    # Get the appropriate pip command
    local pip_cmd=$(get_pip_cmd)
    
    # Uninstall the package
    print_message $YELLOW "  Uninstalling $package_name..."
    $pip_cmd uninstall -y "$package_name" || true
    
    # Clear pip cache for this package
    print_message $YELLOW "  Clearing pip cache..."
    $pip_cmd cache remove "$package_name" || true
    
    # Reinstall from git with force upgrade
    print_message $YELLOW "  Installing latest version from git..."
    $pip_cmd install --force-reinstall --no-cache-dir --no-deps "$git_url"
    
    print_message $GREEN "✅ Successfully updated $package_name"
}

# Function to register this script globally
register_global() {
    echo "🔧 Registering git-update command globally..."
    
    # Get the absolute path to the script
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    # Check write permissions for /usr/local/bin
    if [ -w /usr/local/bin ]; then
        ln -sf "$SCRIPT_PATH" /usr/local/bin/git-update
        print_message $GREEN "✅ git-update command successfully registered!"
        print_message $BLUE "💡 Now you can use 'git-update' from any folder"
    else
        print_message $YELLOW "🔐 Administrator rights are required to register the command:"
        echo "sudo ln -sf '$SCRIPT_PATH' /usr/local/bin/git-update"
        echo ""
        print_message $YELLOW "Or add this command to your ~/.bashrc:"
        echo "alias git-update='$SCRIPT_PATH'"
    fi
}

# Function to uninstall global command
uninstall_global() {
    echo "🗑️ Removing git-update command..."
    
    # Check write permissions for /usr/local/bin
    if [ -w /usr/local/bin ]; then
        if rm -f /usr/local/bin/git-update 2>/dev/null; then
            print_message $GREEN "✅ Successfully removed global command: git-update"
        else
            print_message $YELLOW "⚠️ Global command not found or already removed"
        fi
    else
        print_message $YELLOW "🔐 Administrator rights are required to remove the command:"
        echo "sudo rm -f /usr/local/bin/git-update"
        echo ""
        print_message $YELLOW "Or remove alias from your ~/.bashrc if you used that method"
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
    
    # Check virtual environment (will create/activate if needed)
    check_venv
    
    # Get the appropriate pip command
    local pip_cmd=$(get_pip_cmd)
    print_message $BLUE "🔧 Using pip command: $pip_cmd"
    
    # Parse requirements.txt for dependencies
dependencies=$(grep -v "^#" requirements.txt | tr -d '\r' | grep -v "^$")

    # Update each dependency
    while IFS= read -r dep; do
        # Skip empty lines and comments
        [[ -z "$dep" || "$dep" =~ ^[[:space:]]*# ]] && continue
        
        if [[ $dep == *"git+ssh://"* || $dep == *"git+https://"* ]]; then
            # Extract package name и git URL для @ синтаксиса
            if [[ $dep == *" @ "* ]]; then
                package_name=$(echo "$dep" | cut -d' ' -f1)
                git_url=$(echo "$dep" | sed 's/.* @ //')
            else
                # Обработка прямых git+ssh/git+https URL
                package_name=$(basename "$dep" .git | sed 's/.*\///')
                git_url="$dep"
            fi
            update_git_package "$package_name" "$git_url"
        else
            print_message $BLUE "🔄 Updating $dep..."
            $pip_cmd install --upgrade "$dep"
            print_message $GREEN "✅ Successfully updated $dep"
        fi
        echo  # Empty line for readability
    done <<< "$dependencies"

    # Show installed packages
    print_message $BLUE "📦 Current installed packages:"
    $pip_cmd list
    
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
    echo "  --register       Register this script as global command 'git-update'"
    echo "  --uninstall      Remove global command 'git-update'"
    echo ""
    echo "Requirements:"
    echo "1. Must have requirements.txt in current directory"
    echo "2. Must have SSH access to git repositories"
    echo ""
    echo "Auto-features:"
    echo "• Automatically creates .venv if it doesn't exist"
    echo "• Automatically activates .venv if not activated"
    echo "• Forces updates only in local .venv environment"
    echo ""
    echo "Example:"
    echo "  # Register globally (optional)"
    echo "  ./update_git_deps.sh --register"
    echo ""
    echo "  # Use locally or globally"
    echo "  ./update_git_deps.sh"
    echo "  # or after registration:"
    echo "  git-update"
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
