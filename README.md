# Python Project Updater

Script for updating Python dependencies from git repositories.

## Usage

1. Activate virtual environment:
```bash
source .venv/bin/activate
```

2. Run the update script:
```bash
./update_git_deps.sh
```

## Features

- Forces reinstallation of git-based packages
- Clears pip cache before update
- Supports both direct git URLs and `@ syntax`
- Colored output for better readability
- Virtual environment validation

## Requirements

- Active Python virtual environment
- SSH access to git repositories
- `requirements.txt` file in project directory
