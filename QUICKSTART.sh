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