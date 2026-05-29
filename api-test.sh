#!/bin/bash

################################################################################
# HTTP API Testing Framework - 优化版
# Features: Environment management, variable replacement, template management
# Command-line variable input support, improved error handling
################################################################################

set -euo pipefail

# 脚本基本信息
SCRIPT_VERSION="1.1.0"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# 目录配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
ENV_DIR="${SCRIPT_DIR}/env"
LOGS_DIR="${SCRIPT_DIR}/logs"
RESULTS_DIR="${SCRIPT_DIR}/results"

# 创建必要目录
for dir in "$CONFIG_DIR" "$TEMPLATES_DIR" "$ENV_DIR" "$LOGS_DIR" "$RESULTS_DIR"; do
    mkdir -p "$dir"
done

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 全局变量
LOG_FILE="$LOGS_DIR/api-test.log"
CURRENT_TIMESTAMP=$(date +%s)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d')
SEQ="$(date '+%Y%m%d%H%M%S')$((RANDOM % 10000))"

# 检查依赖
check_dependencies() {
    local deps=("curl" "jq")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Missing dependencies: ${missing_deps[*]}"
        echo "Please install required tools: ${missing_deps[*]}"
        exit 1
    fi
}

# 增强的日志函数
log_info() { 
    local msg="$*"
    echo -e "${BLUE}[INFO]${NC} $msg" | tee -a "$LOG_FILE"
}

log_success() { 
    local msg="$*"
    echo -e "${GREEN}[SUCCESS]${NC} $msg" | tee -a "$LOG_FILE"
}

log_error() { 
    local msg="$*"
    echo -e "${RED}[ERROR]${NC} $msg" | tee -a "$LOG_FILE"
}

log_warning() { 
    local msg="$*"
    echo -e "${YELLOW}[WARNING]${NC} $msg" | tee -a "$LOG_FILE"
}

log_debug() { 
    local msg="$*"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $msg" | tee -a "$LOG_FILE"
    fi
}

# 安全的字符串替换函数
safe_replace() {
    local content="$1"
    local old_str="$2"
    local new_str="$3"
    
    # 使用sed进行安全替换，转义特殊字符
    echo "$content" | sed "s/\$(printf '%s' "$old_str" | sed 's/[[\.*^$()+?{|]/\\&/g')/$(printf '%s' "$new_str" | sed 's/[&/\]/\\&/g')/g"
}

# Load environment file with validation
load_env() {
    local env_name="$1"
    local env_file="$ENV_DIR/${env_name}.env"

    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file not found: $env_file"
        return 1
    fi

    log_info "Loading environment: $env_name"
    
    # 验证环境文件格式
    if ! grep -qE '^[A-Z_][A-Z0-9_]*=' "$env_file" 2>/dev/null; then
        log_warning "Environment file might have incorrect format: $env_file"
    fi
    
    set -a
    # 使用source并捕获错误
    if ! source "$env_file"; then
        log_error "Failed to load environment file: $env_file"
        set +a
        return 1
    fi
    set +a
    
    log_success "Environment loaded: $env_name"
}

# 创建环境文件模板
create_env_template() {
    local env_name="$1"
    local env_file="$ENV_DIR/${env_name}.env"

    if [[ -f "$env_file" ]]; then
        log_warning "Environment file already exists: $env_file"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            return 0
        fi
    fi

    cat > "$env_file" << 'EOF'
# API Configuration
API_BASE_URL="https://api.example.com"
API_VERSION="v1"
TIMEOUT="30"

# Authentication
AUTH_TOKEN=""
AUTH_TYPE="Bearer"

# Default Headers
DEFAULT_ACCEPT="application/json"
DEFAULT_CONTENT_TYPE="application/json"

# Request defaults
DEFAULT_METHOD="GET"
FOLLOW_REDIRECTS="true"
VERIFY_SSL="true"

# Logging and output
LOG_RESPONSES="true"
PRETTY_JSON="true"
EOF

    log_success "Created environment template: $env_file"
}

# 列出环境
list_environments() {
    log_info "Available environments:"
    local env_files=("$ENV_DIR"/*.env)
    if [[ -f "${env_files[0]}" ]]; then
        for env_file in "${env_files[@]}"; do
            if [[ -f "$env_file" ]]; then
                basename "$env_file" .env
            fi
        done
    else
        log_warning "No environment files found"
    fi
}

# 合并CLI变量
merge_variables() {
    local array_name="$1"
    eval "
    for key in \"\${!${array_name}[@]}\"; do
        export \"\$key\"=\"\${${array_name}[\$key]}\"
        log_debug \"Set variable: \$key=\${${array_name}[\$key]}\"
    done
    "
}

# 解析CLI变量
parse_cli_variables() {
    local array_name="$1"
    shift

    while [[ $# -gt 0 ]]; do
        local arg="$1"
        if [[ "$arg" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            eval "$array_name[\"\$key\"]=\"\$value\""
            log_debug "Parsed CLI variable: $key=$value"
        else
            break
        fi
        shift
    done
}

# 改进的递归变量替换函数
replace_variables_recursive() {
    local content="$1"
    local max_iterations=10
    local iteration=0
    local prev_content=""

    # 避免无限循环，当内容不再变化时停止
    while [[ "$content" != "$prev_content" ]] && ((iteration < max_iterations)); do
        prev_content="$content"
        local new_content="$content"
        
        # 查找并替换所有变量
        while [[ "$new_content" =~ \$\{([A-Za-z_][A-Za-z0-9_]*)\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${!var_name:-}"
            # 安全替换，防止特殊字符导致问题
            new_content="${new_content/\$\{$var_name\}/$var_value}"
        done
        
        content="$new_content"
        ((iteration++))
    done

    echo "$content"
}

# 验证变量
validate_variables() {
    local content="$1"
    local missing_vars=()
    local pattern='\$\{([A-Za-z_][A-Za-z0-9_]*)\}'

    # 提取所有未定义的变量
    while [[ "$content" =~ $pattern ]]; do
        local var_name="${BASH_REMATCH[1]}"
        if [[ -z "${!var_name:-}" ]]; then
            if [[ ! " ${missing_vars[@]} " =~ " $var_name " ]]; then
                missing_vars+=("$var_name")
            fi
        fi
        # 替换已处理的匹配项以继续查找
        content="${content/"${BASH_REMATCH[0]}"/}"
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing variables: ${missing_vars[*]}"
        return 1
    fi
    return 0
}

# 提取模板变量
extract_template_variables() {
    local content="$1"
    local array_name="$2"
    local var_pattern='\$\{([A-Za-z_][A-Za-z0-9_]*)\}'

    while [[ "$content" =~ $var_pattern ]]; do
        local var_name="${BASH_REMATCH[1]}"
        eval "$array_name[\"\$var_name\"]=1"
        content="${content//${BASH_REMATCH[0]}/}"
    done
}

# 交互式提示缺失变量
prompt_for_variables() {
    local required_vars_name="$1"
    local cli_vars_name="$2"
    local missing=()

    eval "
    for var in \"\${!${required_vars_name}[@]}\"; do
        if [[ -z \"\${!var:-}\" ]] && [[ -z \"\${${cli_vars_name}[\$var]:-}\" ]]; then
            missing+=(\"\$var\")
        fi
    done
    "

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    log_warning "Missing variables detected: ${missing[*]}"
    echo -e "\n${YELLOW}Please provide values for the following variables:${NC}\n"

    for var in "${missing[@]}"; do
        local prompt_text="$var"
        if [[ -n "${!var:-}" ]]; then
            prompt_text="$var (current: ${!var})"
        fi
        read -p "  $prompt_text = " value
        if [[ -n "$value" ]]; then
            eval "$cli_vars_name[\"\$var\"]=\"\$value\""
        fi
    done
}

# 创建模板
create_template() {
    local template_name="$1"
    local template_file="$TEMPLATES_DIR/${template_name}.json"

    if [[ -f "$template_file" ]]; then
        log_warning "Template file already exists: $template_file"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            return 0
        fi
    fi

    cat > "$template_file" << 'EOF'
{
  "method": "GET",
  "endpoint": "/users",
  "headers": {
    "Authorization": "${AUTH_TYPE} ${AUTH_TOKEN}",
    "Accept": "${DEFAULT_ACCEPT}",
    "Content-Type": "${DEFAULT_CONTENT_TYPE}"
  },
  "query_params": {},
  "body": null,
  "description": "Template for API requests"
}
EOF

    log_success "Created template: $template_file"
}

# 加载模板
load_template() {
    local template_name="$1"
    local template_file="$TEMPLATES_DIR/${template_name}.json"

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 1
    fi
    
    # 验证JSON格式
    if ! jq empty "$template_file" 2>/dev/null; then
        log_error "Invalid JSON format in template: $template_file"
        return 1
    fi
    
    cat "$template_file"
}

# 解析模板中的 @include 指令
resolve_includes() {
    local content="$1"
    local partials_dir="${TEMPLATES_DIR}/partials"
    local max_iterations=10

    while ((max_iterations > 0)); do
        local changed=false
        local new_content="$content"

        while [[ "$new_content" =~ \{\"@include\":[[:space:]]*\"([^\"]+)\"\} ]]; do
            local include_name="${BASH_REMATCH[1]}"
            local partial_file="${partials_dir}/${include_name}.json"

            if [[ ! -f "$partial_file" ]]; then
                log_error "Include partial not found: $include_name ($partial_file)"
                return 1
            fi

            local partial_content
            partial_content=$(cat "$partial_file")
            new_content="${new_content//${BASH_REMATCH[0]}/$partial_content}"
            changed=true
        done

        if [[ "$changed" == "false" ]]; then
            break
        fi

        content="$new_content"
        ((max_iterations--))
    done

    echo "$content"
}

# 列出模板
list_templates() {
    log_info "Available templates:"
    local template_files=("$TEMPLATES_DIR"/*.json)
    if [[ -f "${template_files[0]}" ]]; then
        for template_file in "${template_files[@]}"; do
            if [[ -f "$template_file" ]]; then
                basename "$template_file" .json
            fi
        done
    else
        log_warning "No templates found"
    fi
}

# 显示模板变量
show_template_variables() {
    local template_name="$1"
    local template_json
    template_json=$(load_template "$template_name") || return 1
    template_json=$(resolve_includes "$template_json") || return 1

    declare -A vars
    extract_template_variables "$template_json" vars
    
    if [[ ${#vars[@]} -eq 0 ]]; then
        log_info "Template has no variables"
        return 0
    fi
    
    log_info "Template variables:"
    for var in "${!vars[@]}"; do
        local current_value="${!var:-<not set>}"
        echo "  - $var = $current_value"
    done
}

# 构建curl命令数组 - 通过全局变量CURL_CMD返回
CURL_CMD=()

build_curl_request() {
    local template_json="$1"

    local method
    method=$(jq -r '.method // "GET"' <<< "$template_json")
    local endpoint
    endpoint=$(jq -r '.endpoint // ""' <<< "$template_json")
    local headers
    headers=$(jq -r '.headers // {}' <<< "$template_json")
    local query_params
    query_params=$(jq -r '.query_params // {}' <<< "$template_json")
    local body
    body=$(jq -rc '.body // null' <<< "$template_json")

    local full_url="${API_BASE_URL}${endpoint}"

    # 添加查询参数
    if [[ $(jq 'length' <<< "$query_params") -gt 0 ]]; then
        local query_parts=()
        while IFS= read -r line; do
            query_parts+=("$line")
        done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' <<< "$query_params")

        local query_string
        query_string=$(IFS='&'; echo "${query_parts[*]}")
        full_url="${full_url}?${query_string}"
    fi

    CURL_CMD=("curl" "-s" "-X" "$method")

    # 添加头信息
    while IFS= read -r header_line; do
        CURL_CMD+=("-H" "$header_line")
    done < <(jq -r 'to_entries[] | "\(.key): \(.value)"' <<< "$headers")

    # 添加请求体
    if [[ "$body" != "null" ]]; then
        CURL_CMD+=("-d" "$body")
    fi

    CURL_CMD+=("--connect-timeout" "${TIMEOUT:-30}")
    [[ "${VERIFY_SSL:-true}" == "false" ]] && CURL_CMD+=("-k")

    CURL_CMD+=("$full_url")
}

# 执行HTTP请求 - 优化版本
make_request() {
    local template_name="$1"
    local env_name="${2:-default}"
    local output_file="${3:-}"
    shift 3 || true
    
    declare -A cli_vars
    parse_cli_variables cli_vars "$@"

    if ! load_env "$env_name"; then
        log_error "Failed to load environment: $env_name"
        return 1
    fi
    
    merge_variables cli_vars

    local template_json
    template_json=$(load_template "$template_name") || return 1
    template_json=$(resolve_includes "$template_json") || return 1

    declare -A required_vars
    extract_template_variables "$template_json" required_vars

    if [[ -t 0 ]]; then
        prompt_for_variables required_vars cli_vars
        merge_variables cli_vars
    else
        if ! validate_variables "$template_json"; then
            log_error "Missing required variables. Use: $SCRIPT_NAME send <template> [env] [output-file] VAR=value VAR2=value2"
            return 1
        fi
    fi

    template_json=$(replace_variables_recursive "$template_json")
    
    if ! validate_variables "$template_json"; then
        log_error "Validation failed after variable replacement"
        return 1
    fi

    build_curl_request "$template_json"

    log_info "Executing request: $template_name"
    log_info "Environment: $env_name"
    log_info "URL: ${API_BASE_URL}"
    log_info "Method: $(jq -r '.method // "GET"' <<< "$template_json")"

    local response_file="$RESULTS_DIR/${template_name}_${CURRENT_TIMESTAMP}.json"

    # 直接执行数组，无需eval
    local response_and_code
    response_and_code=$("${CURL_CMD[@]}" -w '\n%{http_code}' 2>&1)
    local response
    response=$(echo "$response_and_code" | sed '$d')
    local http_code
    http_code=$(echo "$response_and_code" | tail -n1)

    # 保存响应到文件
    echo "$response" > "$response_file"

    log_info "HTTP Status Code: $http_code"

    if [[ "${LOG_RESPONSES:-true}" == "true" ]]; then
        if [[ "${PRETTY_JSON:-true}" == "true" ]]; then
            log_info "Response (pretty-printed):"
            if command -v jq >/dev/null 2>&1 && echo "$response" | jq empty 2>/dev/null; then
                echo "$response" | jq '.'
            else
                echo "$response"
            fi
        else
            log_info "Response: $response"
        fi
    fi

    if [[ -n "$output_file" ]]; then
        cp "$response_file" "$output_file"
        log_success "Response saved to: $output_file"
    fi

    if [[ "$http_code" =~ ^[2][0-9]{2}$ ]]; then
        log_success "Request successful"
        return 0
    else
        log_error "Request failed with status code: $http_code"
        return 1
    fi
}

# 干运行
dry_run() {
    local template_name="$1"
    local env_name="${2:-default}"
    shift 2 || true
    
    declare -A cli_vars
    parse_cli_variables cli_vars "$@"
    
    if ! load_env "$env_name"; then
        log_error "Failed to load environment: $env_name"
        return 1
    fi
    
    merge_variables cli_vars

    local template_json
    template_json=$(load_template "$template_name") || return 1
    template_json=$(resolve_includes "$template_json") || return 1
    template_json=$(replace_variables_recursive "$template_json")

    log_info "DRY RUN: $template_name"
    log_info "Environment: $env_name"
    log_info "Generated curl command:"

    build_curl_request "$template_json"
    printf '  %q ' "${CURL_CMD[@]}"
    echo
    
    log_info ""
    log_info "Request details:"
    echo "$template_json" | jq '.'
}

# 初始化项目
init_project() {
    log_info "Initializing API test project (Version $SCRIPT_VERSION)..."
    
    # 创建默认环境
    if [[ ! -f "$ENV_DIR/default.env" ]]; then
        create_env_template "default"
    else
        log_info "Default environment already exists, skipping creation"
    fi
    
    # 创建默认模板
    if [[ ! -f "$TEMPLATES_DIR/get_users.json" ]]; then
        create_template "get_users"
    else
        log_info "Default template already exists, skipping creation"
    fi
    
    log_success "Project initialized successfully"
    log_info "Next steps:"
    log_info "1. Edit env/default.env with your API settings"
    log_info "2. Create request templates in templates/ directory"
    log_info "3. Run: ./$SCRIPT_NAME send <template-name> [env-name] [output-file] [VAR=value ...]"
}

# 显示帮助
show_help() {
    cat << EOF
HTTP API Testing Framework v$SCRIPT_VERSION - Help

Usage: ./$SCRIPT_NAME <command> [options]

Commands:
    init                              Initialize project structure
    
    send <template>           Execute API request from template
                 [env]                (default: "default")
                 [output-file]        (optional: save response)
                 [VAR=value ...]      (optional: override variables)
    
    dry-run <template>                Show request without executing
                 [env]                (default: "default")
                 [VAR=value ...]      (optional: override variables)
    
    show-vars <template>              Show variables in template
    
    create-env <name>                 Create new environment file
    create-template <name>            Create new request template
    
    list-envs                         List available environments
    list-templates                    List available templates
    
    version                           Show script version
    help                              Show this help message

Examples:

  1. Basic request (uses environment variables):
     ./$SCRIPT_NAME send get_users

  2. Request with output file:
     ./$SCRIPT_NAME send get_users default output.json

  3. Request with command-line variables:
     ./$SCRIPT_NAME send create_issue default issue.json \\
       REPO_OWNER=myorg REPO_NAME=myrepo \\
       ISSUE_TITLE="New Feature" ISSUE_BODY="Description"

  4. Override environment variables:
     ./$SCRIPT_NAME send search_repos prod result.json \\
       API_BASE_URL="https://api.github.com" \\
       AUTH_TOKEN="ghp_xxxxxxxxxxxx"

  5. Show template variables:
     ./$SCRIPT_NAME show-vars create_issue

  6. Dry-run to see what would be sent:
     ./$SCRIPT_NAME dry-run create_issue default \\
       REPO_OWNER=myorg REPO_NAME=myrepo

  7. Interactive mode (prompts for missing variables):
     ./$SCRIPT_NAME send create_issue

  8. Non-interactive mode (fails if variables missing):
     ./$SCRIPT_NAME send create_issue < /dev/null

EOF
}

# 显示版本
show_version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# 主路由函数
main() {
    local command="${1:-help}"
    
    # 检查依赖
    check_dependencies

    case "$command" in
        init)
            init_project
            ;;
        send)
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 send <template-name> [env-name] [output-file] [VAR=value ...]"
                return 1
            fi
            shift
            make_request "$@"
            ;;
        dry-run)
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 dry-run <template-name> [env-name] [VAR=value ...]"
                return 1
            fi
            shift
            dry_run "$@"
            ;;
        show-vars)
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 show-vars <template-name>"
                return 1
            fi
            show_template_variables "$2"
            ;;
        create-env)
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 create-env <env-name>"
                return 1
            fi
            create_env_template "$2"
            ;;
        create-template)
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 create-template <template-name>"
                return 1
            fi
            create_template "$2"
            ;;
        list-envs)
            list_environments
            ;;
        list-templates)
            list_templates
            ;;
        version)
            show_version
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
