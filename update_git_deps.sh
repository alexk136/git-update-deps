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
    
    # Reinstall dependencies in case they were missed
    pip install --no-cache-dir "$git_url"
    
    print_message $GREEN "✅ Successfully updated $package_name"
}

# Main function
main() {
    print_message $BLUE "🚀 Starting git dependencies update..."
    
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
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Before running this script:"
    echo "1. Make sure your virtual environment is activated"
    echo "2. Ensure you have SSH access to the git repositories"
    echo ""
    echo "Example:"
    echo "  source .venv/bin/activate"
    echo "  ./update_git_deps.sh"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
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
