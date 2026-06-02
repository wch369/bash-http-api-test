#!/bin/bash

# Make script executable
chmod +x curlman

# Initialize
./curlman init

# Update default.env with your token
# nano env/default.env

# Test examples:
echo "=== Example 1: Show template variables ==="
./curlman show-vars get_user

echo -e "\n=== Example 2: Dry-run request ==="
./curlman dry-run get_user default USERNAME="github"

echo -e "\n=== Example 3: Execute request with variable override ==="
./curlman send get_user default user_result.json USERNAME="torvalds"

echo -e "\n=== Example 4: Create issue with variables ==="
./curlman send create_issue default issue_result.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Test from CLI" \
  ISSUE_BODY="This issue was created via command-line variables"

echo -e "\n=== Example 5: Search repos ==="
./curlman send search_repos default search_result.json \
  SEARCH_QUERY="language:go stars:>10000" \
  SORT_BY="stars" \
  PER_PAGE="5"

echo -e "\n=== Example 6: Create XML template ==="
./curlman create-xml-template xml_request

echo -e "\n=== Example 7: Send XML request ==="
./curlman dry-run xml_request default USERNAME="testuser"

echo -e "\n=== Example 8: Module-based template ==="
./curlman create-template etcp/get_users

echo -e "\n=== Example 9: Module template dry-run ==="
./curlman dry-run etcp/get_users default USERNAME="testuser"

echo -e "\n=== Example 10: List templates (shows module grouping) ==="
./curlman list-templates

echo -e "\n=== Example 11: @include with variable-only override keys ==="
echo "Keys matching \${KEY} in the partial (like SYS_ID) are consumed for"
echo "variable substitution and NOT added to the request body."
echo "See templates/host/etcp-host-062.json and templates/partials/host/host_sys_head.json"
./curlman dry-run host/etcp-host-062 sit1 \
  SYS_ID=3025 SND_DT=20270321 SND_TM=120000 SND_SEQ=0000001 acctNo=6227001234567890