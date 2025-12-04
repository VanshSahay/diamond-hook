# Publishing Guide

Complete guide to publish the Diamond Hook package to GitHub.

## ✅ Pre-Publishing Checklist

- [x] All contracts compile successfully
- [x] Package structure is clean
- [x] Documentation is complete
- [x] Examples work correctly
- [x] License file included
- [x] Version set in package.json (v0.1.0)

## 🚀 Publishing Steps

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name**: `diamond-hook`
3. **Description**: `A Uniswap v4 hook that acts as a diamond proxy, enabling modular hook logic via facets`
4. Set to **Public** ⚠️ (required for Foundry install)
5. **DO NOT** initialize with README, .gitignore, or license
6. Click **"Create repository"**

### Step 2: Initialize Git and Push

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Diamond Hook package v0.1.0"

# Add remote
git remote add origin https://github.com/VanshSahay/diamond-hook.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Create Version Tag

```bash
# Create annotated tag
git tag -a v0.1.0 -m "Initial release: Diamond Hook package"

# Push tag
git push origin v0.1.0
```

### Step 4: Create GitHub Release

1. Go to: https://github.com/VanshSahay/diamond-hook/releases/new
2. **Tag**: Select `v0.1.0`
3. **Title**: `v0.1.0 - Initial Release`
4. **Description**:
   ```markdown
   Initial release of Diamond Hook package for Uniswap v4.
   
   ## Features
   - HookDiamond contract (hook IS the diamond proxy)
   - Modular facet system for custom hook logic
   - Example facets and deployment scripts
   - Complete documentation
   
   ## Installation
   ```bash
   forge install VanshSahay/diamond-hook
   ```
   ```
5. Click **"Publish release"**

## 📦 Quick Publish Script

I've created `PUBLISH_NOW.sh` for you! Just run:

```bash
./PUBLISH_NOW.sh
```

This will:
- Initialize git (if needed)
- Add remote
- Push to GitHub
- Create and push tag v0.1.0

Then manually create the GitHub release.

## ✅ Verification

Test installation:

```bash
# In a test directory
mkdir test-install && cd test-install
forge init --no-git
forge install VanshSahay/diamond-hook
echo "diamond-hook/=lib/diamond-hook/src/" >> remappings.txt
forge build
```

If `forge build` succeeds, your package is working! 🎉

## 📝 Package Contents

Users will get:

```
lib/diamond-hook/
├── src/
│   ├── hook/HookDiamond.sol          # Main contract ⭐
│   ├── diamond/                      # Diamond infrastructure
│   ├── interfaces/IHookFacet.sol
│   └── examples/SimpleCounterFacet.sol
├── script/examples/                   # Deployment scripts
├── README.md                          # Main docs
├── USAGE.md                           # Usage guide
└── LICENSE                            # MIT License
```

## 🔄 Updating the Package

When you make changes:

```bash
# Make changes
git add .
git commit -m "Description of changes"

# Update version tag
git tag -a v0.1.1 -m "Release notes"
git push origin main
git push origin v0.1.1

# Create new release on GitHub
```

## 📊 Versioning

- **v0.1.0** → **v0.2.0**: New features (backwards compatible)
- **v0.1.0** → **v0.1.1**: Bug fixes (backwards compatible)  
- **v0.1.0** → **v1.0.0**: Breaking changes

## 🎯 Installation URL

Once published, users install with:

```bash
forge install VanshSahay/diamond-hook
```

Or in `foundry.toml`:

```toml
[dependencies]
diamond-hook = { git = "https://github.com/VanshSahay/diamond-hook.git", tag = "v0.1.0" }
```

## 📢 Sharing

After publishing:
1. Share on Twitter/X with the GitHub link
2. Post in Uniswap Discord/community
3. Consider adding to Uniswap v4 awesome lists
4. Keep documentation updated

## 🆘 Troubleshooting

**"Repository not found"**
- Make sure repository is **Public**
- Check repository name matches exactly

**"Tag not found"**
- Make sure you pushed the tag: `git push origin v0.1.0`
- Tags are case-sensitive

**"Package won't build"**
- Check remappings.txt includes: `diamond-hook/=lib/diamond-hook/src/`
- Verify all dependencies are installed
