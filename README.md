# HTTP API Testing Framework

A comprehensive bash-based framework for testing HTTP APIs with curl, featuring environment management, variable replacement, and template-based requests with command-line variable input.

## Quick Start

### 1. Initialize Project
```bash
chmod +x api-test.sh
./api-test.sh init
```

### 2. Configure Environment
Edit `env/default.env` with your API credentials:
```bash
API_BASE_URL="https://api.github.com"
AUTH_TOKEN="ghp_your_token_here"
```

### 3. Create a Template
```bash
./api-test.sh create-template my_api_call
```

### 4. Execute Request with Command-Line Variables
```bash
./api-test.sh make-request my_api_call default output.json \
  USERNAME="octocat" \
  CUSTOM_VAR="custom_value"
```

## Key Features

### ✨ Command-Line Variable Input
Override any variable directly from the command line without modifying files:

```bash
# Override template variables
./api-test.sh make-request create_issue default issue.json \
  REPO_OWNER=myorg REPO_NAME=myrepo \
  ISSUE_TITLE="New Feature" ISSUE_BODY="Description"

# Override environment variables
./api-test.sh make-request search_repos prod result.json \
  AUTH_TOKEN="new-token-here" API_BASE_URL="https://api.example.com"
```

### 📋 Variable Priority Order
1. **Command-line arguments** (highest priority) - `VAR=value`
2. **Environment file variables** - `env/*.env`
3. **System environment variables** - inherited from shell
4. **Interactive prompts** (if running in terminal)

### 🔄 Environment Management
- Multiple environments: dev, staging, production
- Easy environment switching
- Variable override at runtime

```bash
./api-test.sh create-env production
./api-test.sh make-request get_users production output.json
```

### 📝 Template Management
- JSON-based request templates
- Variable substitution with `${VAR_NAME}` syntax
- Headers, query parameters, and body support
- Request descriptions

### 🧪 Testing Features
- **Dry-run mode**: Preview request before executing
- **Show-vars**: List template variables
- **Interactive mode**: Prompts for missing variables
- **Non-interactive mode**: For CI/CD pipelines
- **Logging**: Detailed request/response logs
- **Pretty-printing**: Formatted JSON output

## Usage Examples

### Example 1: Basic Request
```bash
# Uses all variables from env/default.env
./api-test.sh make-request get_user
```

### Example 2: Override Specific Variables
```bash
# Keep environment defaults but override USERNAME
./api-test.sh make-request get_user default result.json \
  USERNAME="github"
```

### Example 3: Create Issue with Full Variable Override
```bash
./api-test.sh make-request create_issue default issue.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Found a bug" \
  ISSUE_BODY="I found a bug in the code" \
  ASSIGNEE="developer"
```

### Example 4: Search with Query Parameters
```bash
./api-test.sh make-request search_repos default result.json \
  SEARCH_QUERY="language:javascript stars:>5000" \
  SORT_BY="stars" \
  PER_PAGE="50"
```

### Example 5: Dry-run to Preview
```bash
# See exactly what will be sent (no actual request)
./api-test.sh dry-run create_issue default \
  REPO_OWNER="myorg" \
  REPO_NAME="myrepo" \
  ISSUE_TITLE="Test"
```

### Example 6: Show Template Variables
```bash
# List all variables needed by template
./api-test.sh show-vars create_issue
```

Output:
```
[INFO] Template variables:
  - REPO_OWNER
  - REPO_NAME
  - ISSUE_TITLE
  - ISSUE_BODY
  - ASSIGNEE
  - AUTH_TYPE
  - AUTH_TOKEN
  - DEFAULT_ACCEPT
  - DEFAULT_CONTENT_TYPE
```

### Example 7: Interactive Mode
```bash
# Prompts for missing variables
./api-test.sh make-request create_issue

# Output:
# [WARNING] Missing variables detected: REPO_OWNER REPO_NAME ISSUE_TITLE
# 
# Please provide values for the following variables:
# 
#   REPO_OWNER = myorg
#   REPO_NAME = myrepo
#   ISSUE_TITLE = New Feature
```

### Example 8: Non-Interactive (CI/CD)
```bash
# Fails cleanly if variables missing
./api-test.sh make-request create_issue < /dev/null \
  REPO_OWNER="org" REPO_NAME="repo" \
  ISSUE_TITLE="Test" ISSUE_BODY="Test"
```

### Example 9: Switch Environments
```bash
# Test same template against different environments
./api-test.sh make-request get_user dev result_dev.json
./api-test.sh make-request get_user prod result_prod.json
```

### Example 10: Multiple Variables with Complex Values
```bash
./api-test.sh make-request create_issue default result.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Bug: Login not working" \
  ISSUE_BODY="Login fails on Chrome. Steps to reproduce: 1. Open site 2. Click login"
```

## Command Reference

### Initialize
```bash
./api-test.sh init
```
Creates default environment and template files.

### Make Request
```bash
./api-test.sh make-request <template> [env] [output-file] [VAR=value ...]
```
Execute API request with optional variable overrides.

### Dry Run
```bash
./api-test.sh dry-run <template> [env] [VAR=value ...]
```
Preview request without executing.

### Show Variables
```bash
./api-test.sh show-vars <template>
```
List variables needed by template.

### Create Environment
```bash
./api-test.sh create-env <name>
```
Create new environment file.

### Create Template
```bash
./api-test.sh create-template <name>
```
Create new request template.

### List Environments
```bash
./api-test.sh list-envs
```
Show available environments.

### List Templates
```bash
./api-test.sh list-templates
```
Show available templates.

### Help
```bash
./api-test.sh help
```
Display help information.

## Variable Syntax

### In Templates
Use `${VAR_NAME}` format:
```json
{
  "endpoint": "/repos/${REPO_OWNER}/${REPO_NAME}/issues",
  "headers": {
    "Authorization": "${AUTH_TYPE} ${AUTH_TOKEN}"
  },
  "body": "{\"title\":\"${ISSUE_TITLE}\"}"
}
```

### In Command Line
Use `KEY=value` format:
```bash
./api-test.sh make-request template env output.json KEY=value KEY2="value with spaces"
```

### In Environment Files
Use shell variable syntax:
```bash
API_BASE_URL="https://api.github.com"
AUTH_TOKEN="ghp_xxxxxxxxxxxx"
USERNAME="octocat"
```

## Directory Structure

```
.
├── api-test.sh              # Main script
├── env/                     # Environment configurations
│   ├── default.env
│   └── prod.env
├── templates/               # Request templates
│   ├── create_issue.json
│   ├── search_repos.json
│   └── get_user.json
├── logs/                    # Request logs
│   └── api-test.log
├── results/                 # Response files
│   └── *.json
├── config/                  # Additional configs
└── README.md
```

## Best Practices

1. **Environment Secrets**: Store sensitive data in environment files
```bash
# env/prod.env
AUTH_TOKEN="ghp_production_token"
```

2. **Version Control**: Add env files to `.gitignore`
```bash
echo "env/*.env" >> .gitignore
```

3. **Reusable Defaults**: Set common values in environment files
```bash
# env/default.env
REPO_OWNER="myorg"
API_BASE_URL="https://api.github.com"
```

4. **Template Naming**: Use descriptive names
```bash
./api-test.sh create-template create_github_issue
./api-test.sh create-template list_github_repos
```

5. **Dry-Run Before Execute**: Always preview complex requests
```bash
./api-test.sh dry-run create_issue default \
  REPO_OWNER="org" REPO_NAME="repo"
./api-test.sh make-request create_issue default issue.json \
  REPO_OWNER="org" REPO_NAME="repo"
```

## Troubleshooting

### Missing Variables Error
If you get missing variable errors:

```bash
# 1. Check template variables
./api-test.sh show-vars template_name

# 2. Verify environment file
cat env/default.env

# 3. Provide variables on command-line
./api-test.sh make-request template default VAR=value
```

### SSL Certificate Errors
For development/testing (not recommended for production):

```bash
# Edit environment file
echo 'VERIFY_SSL="false"' >> env/dev.env
```

### Invalid JSON in Template
```bash
# Validate template syntax
jq . templates/template_name.json
```

### Response Not Pretty-Printed
```bash
# Enable pretty-printing in environment
echo 'PRETTY_JSON="true"' >> env/default.env
```

## Advanced Usage

### CI/CD Integration
```bash
#!/bin/bash
set -e

# Run tests in non-interactive mode
./api-test.sh make-request get_user prod < /dev/null \
  USERNAME="test-user"

./api-test.sh make-request create_issue prod issue.json \
  REPO_OWNER="org" REPO_NAME="repo" \
  ISSUE_TITLE="CI/CD Test"
```

### Custom Variable Sets
Create environment-specific files:
```bash
./api-test.sh create-env staging
# Edit env/staging.env with staging-specific values
./api-test.sh make-request template staging result.json
```

### Batch Testing
```bash
#!/bin/bash

for user in user1 user2 user3; do
  ./api-test.sh make-request get_user default "result_${user}.json" \
    USERNAME="$user"
done
```

## Requirements

- Bash 4.0+
- curl
- jq (for JSON parsing)

### Installation

**macOS:**
```bash
brew install curl jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get install curl jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl jq
```

## License

MIT