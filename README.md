# Python Project Updater

Smart script for updating Python dependencies from git repositories with automatic virtual environment management.

## Quick Start

```bash
# 1. Register the command globally (optional)
./update_git_deps.sh --register

# 2. Use from any project directory
cd /path/to/your/project
git-update
```

That's it! The script will automatically:
- Create `.venv` if it doesn't exist
- Activate the virtual environment
- Update all dependencies from `requirements.txt`

## Installation

### Global Registration (Recommended)
```bash
# Clone and register
git clone <repo-url>
cd python_project_updater
./update_git_deps.sh --register
```

### Local Usage
```bash
# Direct usage without registration
./update_git_deps.sh
```

## Usage Options

```bash
git-update [OPTIONS]

Options:
  -h, --help       Show help message
  --register       Register as global command 'git-update'
  --uninstall      Remove global command
```

## Features

### 🚀 Smart Automation
- **Auto-creates** `.venv` virtual environment if missing
- **Auto-activates** virtual environment if not activated
- **Auto-detects** pip (local pip or python -m pip fallback)
- **Force-updates** git-based packages to latest commits

### 🔒 Safety & Isolation
- **Only works with local `.venv`** environments
- **Prevents system-wide** package installations
- **Validates environment** before any operations
- **Clear error messages** with helpful instructions

### 📦 Package Support
- **Git SSH URLs**: `git+ssh://git@github.com/user/repo.git`
- **PEP 508 syntax**: `package_name @ git+ssh://git@github.com/user/repo.git`
- **Regular packages**: `requests>=2.28.0`
- **Mixed requirements**: Git and PyPI packages in same file

### 🎨 User Experience
- **Colored output** for better readability
- **Progress indicators** for each operation
- **Detailed logging** of all operations
- **Global command** available from any directory

## Requirements

### Minimal Requirements
- `requirements.txt` file in current directory
- SSH access to git repositories (for git dependencies)
- Python 3.3+ (for venv support)

### Auto-Handled
- ✅ Virtual environment creation/activation
- ✅ Pip installation/detection
- ✅ Package cache management
- ✅ Environment validation

## How It Works

1. **Environment Check**: Ensures `.venv` exists and is activated
2. **Pip Detection**: Uses local pip or falls back to `python -m pip`
3. **Dependency Parsing**: Reads and processes `requirements.txt`
4. **Smart Updates**:
   - **Git packages**: Uninstall → Clear cache → Force reinstall
   - **Regular packages**: Standard upgrade
5. **Verification**: Shows installed packages after completion

## Examples

### Basic Project Setup
```bash
# Your project structure
my-project/
├── requirements.txt
├── src/
└── tests/

# Update dependencies
cd my-project
git-update
```

### Sample requirements.txt
```txt
# Regular PyPI packages
requests>=2.28.0
python-decouple

# Git dependencies with @ syntax
my-package @ git+ssh://git@github.com/user/my-package.git

# Direct git URLs
git+ssh://git@github.com/user/another-package.git
```

## Troubleshooting

### Common Issues

**Error: "requirements.txt not found"**
```bash
# Make sure you're in the project directory
cd /path/to/your/project
ls requirements.txt  # Should exist
```

**Error: "externally-managed-environment"**
```bash
# The script automatically handles this by using local .venv
# No action needed
```

**SSH Access Issues**
```bash
# Ensure SSH key is set up for git repositories
ssh -T git@github.com
```

## Uninstallation

```bash
git-update --uninstall
# or
sudo rm -f /usr/local/bin/git-update
```
