# WordPress Version Automation Setup

This repository now includes automated version management for your WordPress website using GitHub Actions.

## How It Works

### Asset Version Bumping (CSS/JS)
- **Trigger**: Push to `main` or `develop` branches
- **Action**: Automatically detects changes to `.css` and `.js` files
- **Result**: Increments `WEBSITE_CSS_VERSION` and/or `WEBSITE_JS_VERSION` in `config.php`
- **Commit**: Automatically commits changes back to the repository with message "Auto-bump asset versions [skip ci]"

### Website Version Bumping
- **Trigger**: Creating a release (or pre-release) on GitHub
- **Action**: Increments the `WEBSITE_VERSION` in `config.php` (PATCH version by default)
- **Result**: 
  - Regular release: Bumps patch version (e.g., 7.2.3 → 7.2.4)
  - Pre-release: Bumps patch version with `-pre` suffix (e.g., 7.2.3 → 7.2.4-pre)
- **Rollbar**: Notifies Rollbar Deploys API with the new version as revision
- **Commit**: Automatically commits version bump back to repository

## Required Setup

### 1. GitHub Repository Settings
Ensure the repository has the following permissions:
- Actions have write permissions to the repository
- The `GITHUB_TOKEN` has sufficient permissions (this is automatic in most cases)

### 2. Rollbar Integration
Add your Rollbar access token as a repository secret:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `ROLLBAR_ACCESS_TOKEN`
4. Value: Your Rollbar access token (get this from Rollbar → Account Settings → Access Tokens)

### 3. Current Version Format
The automation expects the following format in `config.php`:
```php
class DBoxConfig {
    const WEBSITE_VERSION = '7.2.3'; // Semantic version (MAJOR.MINOR.PATCH)
    const WEBSITE_CSS_VERSION = 3;   // Simple integer
    const WEBSITE_JS_VERSION = 4;    // Simple integer
}
```

## Workflow Details

### Asset Version Workflow (`push` to main/develop)
1. Detects changed `.css` and `.js` files since last commit
2. If CSS files changed: increments `WEBSITE_CSS_VERSION`
3. If JS files changed: increments `WEBSITE_JS_VERSION`
4. Commits changes with `[skip ci]` to prevent infinite loops
5. Only runs if actual CSS/JS files were modified

### Website Version Workflow (`release` created)
1. Extracts current website version from `config.php`
2. Increments PATCH version (or adds `-pre` for prereleases)
3. Updates `config.php` with new version
4. Commits the version bump
5. Notifies Rollbar with deployment information

## Usage Examples

### Creating a Release
1. Go to your repository → Releases → Create a new release
2. Choose or create a tag (e.g., `v7.2.4`)
3. Fill in release title and description
4. Click "Publish release"
5. The workflow will automatically:
   - Bump the website version to 7.2.4
   - Update `config.php`
   - Commit the change
   - Notify Rollbar

### Making CSS/JS Changes
1. Edit any `.css` or `.js` files
2. Commit and push to `main` or `develop`
3. The workflow will automatically:
   - Detect the file type changes
   - Increment the appropriate version constant(s)
   - Commit the version bump

## Manual Version Management

If you need to manually bump versions, you can edit `config.php` directly or use the provided helper script (see `scripts/bump-version.sh`).

## Troubleshooting

### Common Issues
1. **Workflow not running**: Check that Actions are enabled in repository settings
2. **Permission errors**: Ensure Actions have write permissions
3. **Rollbar notification fails**: Verify `ROLLBAR_ACCESS_TOKEN` secret is set correctly
4. **Version format issues**: Ensure versions follow the expected format

### Logs
Check the Actions tab in your repository to see detailed logs of workflow runs.

## Version History Tracking
All version changes are tracked in git commits, making it easy to:
- See when versions were bumped
- Correlate version changes with code changes
- Roll back if needed

The automation adds clear commit messages like:
- "Auto-bump asset versions [skip ci]"
- "Bump website version to 7.2.4"