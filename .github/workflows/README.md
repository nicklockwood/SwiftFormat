# GitHub Actions Workflows

This directory contains the GitHub Actions workflows for the SwiftFormat repository.

## Workflows

### label_fixed_issues.yml

**Purpose**: Automatically adds the "fixed in develop" label to issues referenced in merged pull requests.

**Trigger**: Runs when a pull request is merged to the `develop` branch.

**How it works**:
1. When a PR is merged to `develop`, the workflow extracts issue references from the PR title and body
2. It looks for common issue reference patterns like:
   - `fixes #123`
   - `closes #456`
   - `resolves #789`
   - `#123` (standalone issue reference)
3. For each referenced issue, it adds the "fixed in develop" label
4. If the label doesn't exist in the repository, it creates it automatically (green color)

**Usage**: To have issues automatically labeled when merging a PR, simply reference the issue numbers in your PR title or description using any of the supported patterns above.

**Example PR description**:
```
This PR fixes #123 and resolves #456.

Also addresses issue #789.
```

When this PR is merged to `develop`, issues #123, #456, and #789 will all receive the "fixed in develop" label.
