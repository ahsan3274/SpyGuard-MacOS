# SpyGuard macOS Port - Git Fork Setup

## Creating Your Fork on GitHub

### Step 1: Fork the Repository

1. Go to the original repository: https://github.com/SpyGuard/SpyGuard
2. Click the **"Fork"** button in the top-right corner
3. Choose your GitHub account/organization
4. Wait for the fork to complete

### Step 2: Clone Your Fork

```bash
# Clone YOUR fork (replace YOUR_USERNAME)
cd /Users/ahsan/Documents/GitHub
git clone https://github.com/YOUR_USERNAME/SpyGuard.git
cd SpyGuard
```

### Step 3: Set Up Remote Tracking

```bash
# Verify your origin remote
git remote -v
# Should show YOUR fork URL

# Add the original repo as 'upstream' (to pull updates later)
git remote add upstream https://github.com/SpyGuard/SpyGuard.git

# Verify remotes
git remote -v
# Should show:
# origin    https://github.com/YOUR_USERNAME/SpyGuard.git (fetch)
# origin    https://github.com/YOUR_USERNAME/SpyGuard.git (push)
# upstream  https://github.com/SpyGuard/SpyGuard.git (fetch)
# upstream  https://github.com/SpyGuard/SpyGuard.git (push)
```

### Step 4: Create a Branch for macOS Port

```bash
# Create and switch to a new branch
git checkout -b macos-port

# Or for MISP integration focus
git checkout -b feature/misp-guard-integration

# Or for macOS-specific work
git checkout -b platform/macos-native
```

### Step 5: Commit Your Changes

```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "feat: Add native macOS port with MISP Guard integration

- Add install-macos.sh with Homebrew-based installation
- Create launchd service management (3 LaunchDaemons)
- Implement platform abstraction layer (Linux/macOS)
- Integrate MISP Guard for IOC filtering
- Add compartment-based filtering rules
- Configure Suricata for PCAP capture on bridge100
- Update Python dependencies for macOS compatibility
- Add comprehensive documentation for macOS setup
- Create Internet Sharing setup guide

Features:
- Native macOS support (Intel + Apple Silicon)
- MISP Guard filtering (tags, distribution levels, compartments)
- Platform detection and unified API
- Updated requirements.txt (CPI fork improvements)

Documentation:
- README-macos.md (main guide)
- docs/macos-internet-sharing-setup.md
- MACOS_PORT_SUMMARY.md (implementation details)

Signed-off-by: Your Name <your.email@example.com>"
```

### Step 6: Push to Your Fork

```bash
# Push the branch to YOUR fork
git push -u origin macos-port

# Output should show:
# Branch 'macos-port' set up to track remote branch 'macos-port' from 'origin'
```

### Step 7: Create Pull Request (Optional)

If you want to contribute back to the original project:

1. Go to your fork on GitHub: `https://github.com/YOUR_USERNAME/SpyGuard`
2. Click **"Compare & pull request"**
3. Select:
   - **base repository:** `SpyGuard/SpyGuard:master`
   - **head repository:** `YOUR_USERNAME/SpyGuard:macos-port`
4. Add a descriptive title and description
5. Click **"Create pull request"**

---

## Keeping Your Fork Updated

### Sync with Upstream

```bash
# Fetch upstream changes
git fetch upstream

# Checkout your main branch
git checkout master

# Merge upstream changes
git merge upstream/master

# Push to your fork
git push origin master
```

### Rebase Your Feature Branch

```bash
# Checkout your feature branch
git checkout macos-port

# Rebase on updated master
git rebase master

# Force push if needed (be careful!)
git push -f origin macos-port
```

---

## Git Configuration (Recommended)

### Set Your Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Use SSH Instead of HTTPS (Optional but Recommended)

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy the output and add to: https://github.com/settings/keys

# Change remote URLs to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/SpyGuard.git
git remote set-url upstream git@github.com:SpyGuard/SpyGuard.git
```

### Useful Git Aliases

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.last "log -1 HEAD"
git config --global alias.lg "log --oneline --graph --all"
```

---

## Recommended .gitignore Additions for macOS

Add these to `.gitignore` if not already present:

```gitignore
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# macOS port specific
spyguard-venv/
config/config.yaml
server/backend/*.pem
server/frontend/*.pem
database.sqlite3
*.log
logs/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
```

---

## Branch Naming Conventions

Follow conventional commit branching:

- `feature/` - New features (e.g., `feature/misp-guard-integration`)
- `fix/` - Bug fixes (e.g., `fix/suricata-config-macos`)
- `docs/` - Documentation (e.g., `docs/macos-setup-guide`)
- `platform/` - Platform-specific (e.g., `platform/macos-native`)
- `refactor/` - Code refactoring (e.g., `refactor/platform-abstraction`)
- `test/` - Tests (e.g., `test/macos-installation`)

---

## Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Tests
- `chore:` Maintenance

### Example

```
feat(macos): Add launchd service management

Create three LaunchDaemons for frontend, backend, and watchers.
Configure auto-start on boot with proper logging.

Closes #123
```

---

## Quick Reference

```bash
# Initial setup (one-time)
git clone https://github.com/YOUR_USERNAME/SpyGuard.git
cd SpyGuard
git remote add upstream https://github.com/SpyGuard/SpyGuard.git
git checkout -b macos-port

# Daily workflow
git pull upstream master          # Get latest changes
git checkout macos-port          # Switch to your branch
git add -A                       # Stage changes
git commit -m "feat: description" # Commit
git push origin macos-port       # Push to fork

# Sync fork
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

---

## Next Steps

1. ✅ **Create GitHub account** (if you don't have one)
2. ✅ **Fork the repository** on GitHub
3. ✅ **Clone your fork** locally
4. ✅ **Set up upstream remote**
5. ✅ **Create feature branch**
6. ✅ **Commit and push changes**
7. ✅ **Create pull request** (optional)

---

## Your Fork URL

After forking, your repository will be at:

```
https://github.com/YOUR_USERNAME/SpyGuard
```

Replace `YOUR_USERNAME` with your actual GitHub username.
