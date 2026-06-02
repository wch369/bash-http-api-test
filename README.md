# HTTP API Testing Framework

A comprehensive bash-based framework for testing HTTP APIs with curl, featuring environment management, variable replacement, and template-based requests with command-line variable input.

## Quick Start

### 1. Initialize Project
```bash
chmod +x curlman
./curlman init
```

### 2. Configure Environment
Edit `env/default.env` with your API credentials:
```bash
# Option A: Use API_HOST + API_PORT (recommended)
API_HOST="api.github.com"
API_PORT=""
API_SCHEMA="https"

# Option B: Full URL (backward-compatible)
# API_BASE_URL="https://api.github.com"

AUTH_TOKEN="ghp_your_token_here"
```

### 3. Create a Template
```bash
./curlman create-template my_api_call
```

### 4. Execute Request with Command-Line Variables
```bash
./curlman send my_api_call default output.json \
  USERNAME="octocat" \
  CUSTOM_VAR="custom_value"
```

## Key Features

### 📦 Request Body Formats
Support for both JSON and XML request bodies:

```bash
# JSON body (object serialized automatically)
./curlman create-template json_api

# XML body (raw string, set Content-Type accordingly)
./curlman create-xml-template xml_api
```

### ✨ Command-Line Variable Input
Override any variable directly from the command line without modifying files:

```bash
# Override template variables
./curlman send create_issue default issue.json \
  REPO_OWNER=myorg REPO_NAME=myrepo \
  ISSUE_TITLE="New Feature" ISSUE_BODY="Description"

# Override environment variables
./curlman send search_repos prod result.json \
  AUTH_TOKEN="new-token-here" API_BASE_URL="https://api.example.com"
```

### 📋 Variable Priority Order
1. **Command-line arguments** (highest priority) - `VAR=value`
2. **Environment file variables** - `env/*.env`
3. **System environment variables** - inherited from shell
4. **Template @include overrides** - inline values in `{"@include": "partial", "key": "value"}` or escaped XML element overrides
5. **Partial file defaults** - hardcoded values in `templates/partials/*.json`
6. **Interactive prompts** (lowest) - if running in terminal

### 🔄 Environment Management
- Multiple environments: dev, staging, production
- Easy environment switching
- Split URL: `API_HOST` + `API_PORT` + `API_SCHEMA` (override individually)
- Variable override at runtime

```bash
./curlman create-env production
./curlman send get_users production output.json
```

### 📝 Template Management
- JSON-based request templates
- **Module support**: Organize templates into subdirectories (`module/name` syntax)
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
./curlman send get_user
```

### Example 2: Override Specific Variables
```bash
# Keep environment defaults but override USERNAME
./curlman send get_user default result.json \
  USERNAME="github"
```

### Example 3: Create Issue with Full Variable Override
```bash
./curlman send create_issue default issue.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Found a bug" \
  ISSUE_BODY="I found a bug in the code" \
  ASSIGNEE="developer"
```

### Example 4: Search with Query Parameters
```bash
./curlman send search_repos default result.json \
  SEARCH_QUERY="language:javascript stars:>5000" \
  SORT_BY="stars" \
  PER_PAGE="50"
```

### Example 5: Dry-run to Preview
```bash
# See exactly what will be sent (no actual request)
./curlman dry-run create_issue default \
  REPO_OWNER="myorg" \
  REPO_NAME="myrepo" \
  ISSUE_TITLE="Test"
```

### Example 6: Show Template Variables
```bash
# List all variables needed by template
./curlman show-vars create_issue
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
./curlman send create_issue

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
./curlman send create_issue < /dev/null \
  REPO_OWNER="org" REPO_NAME="repo" \
  ISSUE_TITLE="Test" ISSUE_BODY="Test"
```

### Example 9: Switch Environments
```bash
# Test same template against different environments
./curlman send get_user dev result_dev.json
./curlman send get_user prod result_prod.json
```

### Example 10: Multiple Variables with Complex Values
```bash
./curlman send create_issue default result.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Bug: Login not working" \
  ISSUE_BODY="Login fails on Chrome. Steps to reproduce: 1. Open site 2. Click login"
```

### Example 11: Module-Based Templates
```bash
# Create a module template
./curlman create-template etcp/get_users

# Create module-scoped partial
mkdir -p templates/partials/etcp
echo '{"headers":{"Authorization":"Bearer ${AUTH_TOKEN}"}}' > templates/partials/etcp/common.json

# Send request using module template
./curlman send etcp/get_users default result.json USERNAME="octocat"

# Dry-run to preview module request
./curlman dry-run etcp/get_users default USERNAME="octocat"

# List templates (shows module grouping)
./curlman list-templates
```

## Command Reference

### Initialize
```bash
./curlman init
```
Creates default environment and template files.

### Make Request
```bash
./curlman send <template> [env] [output-file] [VAR=value ...]
```
Execute API request with optional variable overrides. `<template>` supports `module/name` syntax.

### Dry Run
```bash
./curlman dry-run <template> [env] [VAR=value ...]
```
Preview request without executing. `<template>` supports `module/name` syntax.

### Show Variables
```bash
./curlman show-vars <template>
```
List variables needed by template.

### Create Environment
```bash
./curlman create-env <name>
```
Create new environment file.

### Create Template
```bash
./curlman create-template <name>
```
Create new JSON request template. Supports `module/name` syntax for module organization.

### Create XML Template
```bash
./curlman create-xml-template <name>
```
Create new XML request template with `Content-Type: application/xml` preset. Supports `module/name` syntax.

### List Environments
```bash
./curlman list-envs
```
Show available environments.

### List Templates
```bash
./curlman list-templates
```
Show available templates.

### Help
```bash
./curlman help
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

### XML Body Templates
For XML APIs, set the body as a JSON string and use `Content-Type: application/xml`:
```json
{
  "method": "POST",
  "endpoint": "/api/soap",
  "headers": {
    "Content-Type": "application/xml"
  },
  "body": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>\n  <name>${USERNAME}</name>\n</request>"
}
```

### Template Partials (@include)
Reuse common template parts across multiple request templates. Place partial files in `templates/partials/`.

**JSON structure level** — replace a JSON object/field (supports override keys):

```json
{
  "headers": {"@include": "common_headers"}
}
```

Override keys are processed in two ways depending on whether they match a `${KEY}` variable in the partial:

**Variable keys** — keys that match a `${KEY}` pattern inside the partial are consumed for variable substitution only; they are **not** added to the request body:

```json
// Partial: templates/partials/host/host_sys_head.json
{"cnsmrSysId": "${SYS_ID}", "glblSeqNo": "${SYS_ID}${SND_SEQ}"}

// Template: SYS_ID feeds ${SYS_ID} but does not appear in the output
{"sysHead": {"@include": "host_sys_head", "SYS_ID": "3025"}}
```

**Merge keys** — keys that do NOT match any `${KEY}` in the partial are deep-merged normally:

```json
{
  "headers": {"@include": "common_headers", "Accept": "application/xml"}
}
```

The `Accept` value replaces the partial's value; all other fields from the partial are preserved. Nested objects deep-merge.

**Inside string values** (XML bodies, etc.) — embed partials within strings, with optional XML element overrides:

```json
{
  "body": "<?xml version=\"1.0\"?>\n<request>{\"@include\": \"xml_body\"}\n</request>"
}
```

Override specific XML elements inline:

```json
{
  "body": "<?xml version=\"1.0\"?>\n<request>{\"@include\": \"xml_body\", \"name\": \"hardcoded\"}\n</request>"
}
```

This replaces `<name>...</name>` in the partial with `<name>hardcoded</name>`.

Variables (`${VAR}`) inside partials are resolved normally after include processing.

### 📁 Module Organization

Templates and partials can be grouped into modules for better organization in larger projects.

#### Module Templates

Use `module/name` syntax to reference templates in subdirectories:

```bash
# Create a module template
./curlman create-template etcp/get_users

# Use a module template
./curlman send etcp/get_users

# List templates (grouped by module)
./curlman list-templates
```

Output:
```
[INFO] Available templates:
  get_user                     # flat template
  [etcp]                       # module: etcp
    etcp/get_users
    etcp/create_issue
  [ibps]                       # module: ibps
    ibps/search
```

#### Module-Scoped Partials

Partials follow a two-tier lookup: module-scoped first, then shared fallback. Given a template `etcp/get_users` that includes `"@include": "headers"`:

```
1. templates/partials/etcp/headers.json   ← module-scoped (checked first)
2. templates/partials/headers.json         ← shared (fallback)
```

This allows modules to override shared partials with module-specific versions. Partials can also use explicit module prefixes to bypass the fallback:

```json
{
  "@include": "ibps/headers"   // always resolves to partials/ibps/headers.json
}
```

Module-scoped partials support the same override semantics as shared partials (JSON override keys and XML element overrides).

### In Command Line
Use `KEY=value` format:
```bash
./curlman send template env output.json KEY=value KEY2="value with spaces"
```

### In Environment Files
Use shell variable syntax:
```bash
# URL: prefer API_HOST + API_PORT; API_BASE_URL is fallback
API_HOST="api.github.com"
API_PORT=""           # optional, e.g. "8080"
API_SCHEMA="https"
API_BASE_URL=""       # full URL fallback (ignored when API_HOST is set)
AUTH_TOKEN="ghp_xxxxxxxxxxxx"
USERNAME="octocat"
```

API_HOST, API_PORT, and API_SCHEMA can be overridden from the command line or inside templates:
```bash
# Override host and port at runtime
./curlman send get_users default API_HOST=10.0.0.1 API_PORT=9090
```

## Directory Structure

```
.
├── curlman              # Main script
├── env/                     # Environment configurations
│   ├── default.env
│   └── prod.env
├── templates/               # Request templates
│   ├── create_issue.json    # Flat templates (no module)
│   ├── search_repos.json
│   ├── get_user.json
│   ├── etcp/                # Module: etcp
│   │   ├── get_users.json
│   │   └── create_issue.json
│   ├── ibps/                # Module: ibps
│   │   └── search.json
│   └── partials/            # Reusable template parts
│       ├── common_meta.json # Shared partials (all templates)
│       ├── xml_body.json
│       ├── etcp/            # Module-scoped partials (etcp only)
│       │   └── headers.json
│       └── ibps/            # Module-scoped partials (ibps only)
│           └── auth.json
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

4. **Template Naming**: Use descriptive names, organize with modules
```bash
# Flat templates for simple projects
./curlman create-template create_github_issue
./curlman create-template list_github_repos

# Module templates for larger projects
./curlman create-template etcp/get_users
./curlman create-template ibps/search_records
```

5. **Dry-Run Before Execute**: Always preview complex requests
```bash
./curlman dry-run create_issue default \
  REPO_OWNER="org" REPO_NAME="repo"
./curlman send create_issue default issue.json \
  REPO_OWNER="org" REPO_NAME="repo"
```

## Troubleshooting

### Missing Variables Error
If you get missing variable errors:

```bash
# 1. Check template variables
./curlman show-vars template_name

# 2. Verify environment file
cat env/default.env

# 3. Provide variables on command-line
./curlman send template default VAR=value
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
./curlman send get_user prod < /dev/null \
  USERNAME="test-user"

./curlman send create_issue prod issue.json \
  REPO_OWNER="org" REPO_NAME="repo" \
  ISSUE_TITLE="CI/CD Test"
```

### Custom Variable Sets
Create environment-specific files:
```bash
./curlman create-env staging
# Edit env/staging.env with staging-specific values
./curlman send template staging result.json
```

### Batch Testing
```bash
#!/bin/bash

for user in user1 user2 user3; do
  ./curlman send get_user default "result_${user}.json" \
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