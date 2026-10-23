# Project Rules & Guidelines for MamAmie

## Git & Branch Management Policy

1. **NO LOCAL MERGES**: Never execute a local `git merge` between branches (e.g., merging a feature branch into `main` or `develop`).
2. **BRANCH ISOLATION**: Always work exclusively on dedicated feature branches (e.g., `feature/...`).
3. **PULL REQUEST WORKFLOW**: When features, fixes, or changes are completed:
   - Commit changes to the current feature branch.
   - Push the feature branch to `origin/<feature-branch>`.
   - Provide the GitHub Pull Request URL to the user.
   - **Do NOT merge into `main` locally.** The user will review and merge pull requests on GitHub.
4. **NO DIRECT COMMITS TO MAIN**: Never switch to `main` and commit or push to `main` directly unless explicitly commanded with "merge into main".
