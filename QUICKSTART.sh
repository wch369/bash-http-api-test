#!/bin/bash

# Make script executable
chmod +x api-test.sh

# Initialize
./api-test.sh init

# Update default.env with your token
# nano env/default.env

# Test examples:
echo "=== Example 1: Show template variables ==="
./api-test.sh show-vars get_user

echo -e "\n=== Example 2: Dry-run request ==="
./api-test.sh dry-run get_user default USERNAME="github"

echo -e "\n=== Example 3: Execute request with variable override ==="
./api-test.sh send get_user default user_result.json USERNAME="torvalds"

echo -e "\n=== Example 4: Create issue with variables ==="
./api-test.sh send create_issue default issue_result.json \
  REPO_OWNER="octocat" \
  REPO_NAME="Hello-World" \
  ISSUE_TITLE="Test from CLI" \
  ISSUE_BODY="This issue was created via command-line variables"

echo -e "\n=== Example 5: Search repos ==="
./api-test.sh send search_repos default search_result.json \
  SEARCH_QUERY="language:go stars:>10000" \
  SORT_BY="stars" \
  PER_PAGE="5"

echo -e "\n=== Example 6: Create XML template ==="
./api-test.sh create-xml-template xml_request

echo -e "\n=== Example 7: Send XML request ==="
./api-test.sh dry-run xml_request default USERNAME="testuser"