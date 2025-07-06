<!-- markdownlint-disable MD036 -->
# 🧹 GHCR Cleanup Script

> *The Marie Kondo of Docker Images* - "Does this image spark joy? No? DELETE!" 📦✂️

**TL;DR:** Your GHCR is probably a hot mess of old Docker images eating your storage budget. This script swoops in like a digital janitor with OCD and makes everything sparkle! ✨

## 🎯 What It Does

- 🏆 Preserves your VIP images (`latest`, `staging-latest`)
- 🔄 Keeps your recent builds (you decide how many)
- 🗑️ Deletes the digital dust bunnies
- 📊 Shows beautiful colored output while doing it
- 🚀 Works on single packages or nukes entire registries

## 🚀 Quick Start

```bash
# Authenticate like a boss
gh auth login --scopes "read:packages,delete:packages,repo"

# Keep 2 versions per package + special tags (safe choice)
./ghcr-cleanup.sh -k 2 your-username

# Delete everything older than 7 days (YOLO mode)
./ghcr-cleanup.sh -d 7 your-username

# "Show me what you'd delete but don't actually do it" (paranoid mode)
./ghcr-cleanup.sh -n -k 2 your-username
```

## 🎪 Key Features

| Feature | Description | Why You Need This |
|---------|-------------|-------------------|
| **Smart Cleanup** | Keeps important stuff, deletes junk | Your storage bill will thank you 💸 |
| **Special Tag Protection** | Never deletes `latest` or `staging-latest` | Sleep soundly knowing prod is safe 😴 |
| **Bulk Operations** | Clean ALL packages at once | Because ain't nobody got time for manual clicking 🖱️ |
| **Project Filtering** | `-p myproject` cleans only matching packages | Target your mess with surgical precision 🎯 |
| **Dry Run Mode** | `-n` shows what would happen without doing it | For when you trust nobody, not even yourself 🤔 |
| **Untagged Handling** | Treats build artifacts like the trash they are | Your CI/CD leaves digital breadcrumbs everywhere 🍞 |

## 📖 Want the Full Story?

This summary barely scratches the surface! For the **complete guide with all the juicy details, examples, and pro tips**, check out:

### 📚 [**DETAILED DOCUMENTATION →**](DETAILED.md)

*Warning: Contains excessive amounts of helpful information, terrible jokes, and way too many emojis. Side effects may include actually understanding how the script works and becoming dangerously productive.* ⚠️😂

## 🎭 Part of the GitHub Automation Toolkit

This is one script in our growing collection of tools that make GitHub management less painful and more magical! 🎩✨

*Because life's too short to click through web interfaces like it's 2005.* 🖱️💀

---

**Made with ❤️ and excessive amounts of ☕ by developers who got tired of storage bills**
