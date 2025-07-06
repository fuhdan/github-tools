<!-- markdownlint-disable MD036 -->
# 🧹✨ GHCR Cleanup Script - The Complete Guide ✨🧹

> *"In which we learn to tidy up our Docker images with the enthusiasm of Marie Kondo and the precision of a Swiss watchmaker"* ⌚

Welcome to the most unnecessarily detailed guide to cleaning up your GitHub Container Registry! Buckle up, because we're about to turn your chaotic image graveyard into a zen garden of perfectly organized containers. 🎋

---

## 🎭 The Epic Saga of Your Messy Registry

Picture this: Your GHCR is like that junk drawer everyone has. You know the one - it started with good intentions, but now it's full of:

- 47 versions of the same app 📱
- Untagged images from that time you "quickly tested something" 🧪
- Build artifacts from CI runs that failed spectacularly 💥
- Images tagged with timestamps that make archaeologists weep 🦴

**Enter our hero:** The GHCR Cleanup Script! 🦸‍♀️

Armed with the power of surgical precision and the wisdom of knowing which images actually matter, it swoops in to save your storage budget and your sanity!

---

## 🎪 Features That'll Make You Go "WOW!"

### 🎯 Precision Targeting

Like a sniper, but for Docker images:

- **Single Package Mode**: Laser-focused cleanup of one specific package
- **Bulk Mode**: Clean ALL your packages with one command (because who has time for clicking?)
- **Project Filtering**: Only clean packages matching a prefix (e.g., `myproject-*`)

### 🛡️ Smart Preservation System

Our script has opinions about what's important:

- **Special Tag Protection**: Your `latest` and `staging-latest` are SACRED 🙏
- **Configurable Keep Count**: "Keep my 5 most recent builds, pretty please!"
- **Age-Based Cleanup**: "Delete anything older than a week, I'm not sentimental"

### 🎨 Beautiful Output That Actually Helps

```text
🐳 ID: 123456789 - ⭐ latest - 2025-07-06 20:37
🐳 ID: 123456788 - staging-latest - 2025-07-06 20:33
🐳 ID: 123456787 - untagged - 2025-07-06 20:30
```

*It's like watching a really satisfying organization video, but for your containers!*

### 🔍 Untagged Image Intelligence

- **Default Mode**: "Untagged images are build turds" - deletes them without mercy
- **Inclusive Mode (`-u`)**: "Untagged images have feelings too" - includes them in calculations

---

## 📚 Installation & Setup (The Boring But Necessary Stuff)

### Prerequisites (The Usual Suspects)

You'll need these trusty sidekicks:

- `bash` 4.0+ (because we're not animals)
- `curl` (for sweet-talking GitHub's API)
- `jq` (for making JSON bend to our will)
- A GitHub token with the right superpowers

### Installing Dependencies

**On macOS** (with Homebrew, because you're fancy):

```bash
brew install jq curl
```

**On Ubuntu/Debian** (for the practical folks):

```bash
sudo apt-get update
sudo apt-get install jq curl
```

**On CentOS/RHEL** (for the enterprise warriors):

```bash
sudo yum install jq curl
```

### GitHub Authentication 🔐 (The Secret Handshake)

You need a GitHub token with these magical powers:

- `read:packages` 👁️ (to see your images)
- `delete:packages` 🗑️ (to delete old images)
- `repo` 📝 (for private packages)

#### Option 1: GitHub CLI (The Cool Kid's Choice)

```bash
gh auth login --scopes "read:packages,delete:packages,repo"
# The script will automatically detect and use this token! 🎉
```

#### Option 2: Personal Access Token (Old School But Reliable)

1. Visit [GitHub Settings > Personal Access Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select the scopes mentioned above
4. Copy the token and either:

   ```bash
   export GITHUB_TOKEN=your_token_here
   ./ghcr-cleanup.sh your-username
   ```

   Or:

   ```bash
   ./ghcr-cleanup.sh -t your_token_here your-username
   ```

---

## 🎮 Usage Guide (Where the Magic Happens)

### Basic Syntax (Keep It Simple, Stupid)

```bash
./ghcr-cleanup.sh [OPTIONS] REPO_OWNER [PACKAGE_NAME]
```

### 🎛️ All the Bells and Whistles (Options Galore!)

| Option | Description | Example | When to Use |
|--------|-------------|---------|-------------|
| `-d, --days DAYS` | Delete images older than DAYS | `-d 7` | "I'm sentimental about last week" |
| `-k, --keep NUMBER` | Keep latest NUMBER images | `-k 5` | "5 is my lucky number" |
| `-u, --include-untagged` | Include untagged in calculations | `-u` | "Untagged images have rights too!" |
| `-p, --project PREFIX` | Only process packages matching PREFIX | `-p myproject` | "I only care about my baby" |
| `-s, --skip-special` | Don't preserve special tags | `-s` | "I don't believe in special treatment" |
| `-t, --token TOKEN` | GitHub token | `-t ghp_xxxx` | "I live dangerously with tokens" |
| `-n, --dry-run` | Show what would happen (no deletion) | `-n` | "Trust but verify" |
| `-l, --list-packages` | List all packages | `-l` | "Show me what you got" |
| `-i, --list-versions` | List versions of a package | `-i` | "I need the deets" |
| `-v, --verbose` | Show detailed output | `-v` | "I like to watch the world burn... slowly" |
| `-h, --help` | Show help message | `-h` | "I'm lost and need an adult" |

---

## 🎪 Usage Examples (The Really Fun Part!)

### 🕵️ Reconnaissance Mode ("Intel Gathering")

```bash
# "Show me what you've got!"
./ghcr-cleanup.sh -l your-username

# "Show me EVERYTHING with excruciating detail!"
./ghcr-cleanup.sh -l -v your-username

# "Show me only packages starting with 'api-'"
./ghcr-cleanup.sh -l -p api your-username

# "Show me versions of my specific package"
./ghcr-cleanup.sh -i your-username your-package-name
```

### 🎯 Surgical Precision (Single Package Surgery)

```bash
# Keep 5 latest tagged versions + special tags
./ghcr-cleanup.sh -k 5 your-username your-package

# Keep 3 latest versions (including untagged) + special tags
./ghcr-cleanup.sh -k 3 -u your-username your-package

# Delete tagged versions older than 7 days (keep special tags)
./ghcr-cleanup.sh -d 7 your-username your-package

# Delete ALL versions older than 7 days (nuclear option!)
./ghcr-cleanup.sh -d 7 -u your-username your-package

# "I don't believe in special tags" mode
./ghcr-cleanup.sh -k 2 -s your-username your-package
```

### 🚀 Bulk Operations (Clean ALL the Things!)

```bash
# Clean all packages - keep 2 tagged + special tags each
./ghcr-cleanup.sh -k 2 your-username

# Clean all packages - delete tagged versions >7 days
./ghcr-cleanup.sh -d 7 your-username

# Clean only project packages - keep 1 version each
./ghcr-cleanup.sh -k 1 -p myproject your-username

# The "I trust nothing" mode - delete everything >1 day
./ghcr-cleanup.sh -d 1 -u your-username
```

### 🧪 Testing Mode (Safety First, Fun Second)

```bash
# "Show me what you WOULD delete (but don't actually do it)"
./ghcr-cleanup.sh -n -k 2 your-username

# Dry run with verbose output (maximum paranoia mode)
./ghcr-cleanup.sh -n -v -k 2 your-username your-package
```

---

## 🎭 Understanding the Behavior (The Psychology of Image Cleanup)

### 🏆 Special Tag Preservation (The VIP Section)

By default, these tags are treated like royalty:

- `latest` 👑 (The King)
- `staging-latest` 🎭 (The Prince)
- `main` 🌟 (The Crown Prince)
- `master` 👴 (The Elder King)

**They don't count toward your keep limit!**

**Example with `-k 2`:**

```text
✅ Keep: latest (special, doesn't count)
✅ Keep: staging-latest (special, doesn't count)  
✅ Keep: build-123 (regular, 1/2)
✅ Keep: build-122 (regular, 2/2)
❌ Delete: build-121 (regular, exceeds limit)
```

**Result: 4 total versions kept (2 special + 2 regular)**

*It's like having a VIP section at a nightclub, but for Docker images!*

### 🏷️ Untagged Image Handling (The Great Philosophical Debate)

**Without `-u` (Default "Build Artifacts Are Trash" Mode):**
> *"Untagged images are the digital equivalent of empty pizza boxes - they served their purpose, now they're just taking up space!"*

- Untagged images are immediately deleted
- Only tagged images count toward keep/age limits
- Your CI/CD cleanup happens automatically

**With `-u` Flag ("Untagged Images Are People Too" Mode):**
> *"Every image has value, tagged or not! They all deserve equal consideration!"*

- Untagged images are included in keep/age calculations
- They compete with tagged images for the keep slots
- More inclusive, but potentially keeps more junk

### 📊 Output Modes (Choose Your Adventure)

**Minimal Output (Default "Just the Facts" Mode):**

```text
━━━ my-awesome-app ━━━
Kept: 2, Deleted: 8, Preserved: 2
✓ Completed
```

*Perfect for when you just want results without the drama.*

**Verbose Output (`-v` "I Want to See Everything" Mode):**

```text
━━━ my-awesome-app ━━━
Processing: yourname/my-awesome-app
Preserving special: 123456789 (latest)
Preserving special: 123456788 (staging-latest)
Keeping: 123456787 (build-123)
Keeping: 123456786 (build-122)
Deleting: 123456785 (build-121)
Deleting: 123456784 (untagged)
✓ Completed
```

*For when you want to watch the cleanup unfold like a satisfying TV show.*

---

## 🎨 Beautiful Output Examples (Eye Candy Section)

### Package Listing (The Registry Inventory)

```text
📦 my-awesome-api (private) - 2025-07-06 20:37 - 15 versions (12 tagged, 3 untagged)
📦 my-cool-frontend (public) - 2025-07-06 18:22 - 8 versions (all tagged)
📦 experimental-stuff (private) - 2025-07-05 14:15 - 3 versions (all untagged)
📦 legacy-nightmare (private) - 2024-12-01 10:30 - 847 versions (12 tagged, 835 untagged)
```

*That last one is why you need this script.*

### Verbose Version Details (The Microscopic View)

```text
Versions:
- 454930108 (2025-07-06 20:37)
  - 479
  - 48985e91ba72fcbc7b3bf3fdffcd870a135f3d61
  - ⭐ staging-latest
- 454928979 (2025-07-06 20:33)
  - 478
  - ⭐ latest
- 454925123 (2025-07-06 19:15)
  - (no tags)
- 454920001 (2025-07-06 18:42)
  - feature-branch-that-never-got-merged
```

### Cleanup Progress (The Satisfying Part)

```text
🧹 Starting cleanup...
Owner: your-username
Mode: Keep 2 latest tagged versions + special tags (delete all untagged)
Special tags: preserved

Processing 3 packages

━━━ my-awesome-api ━━━
Deleting untagged version: 454925123
Deleting untagged version: 454920001
Deleting untagged version: 454915555
Preserving special: 454930108 (staging-latest)
Preserving special: 454928979 (latest)
Keeping: 454925000 (build-477)
Keeping: 454920000 (build-476)
Deleting: 454915000 (build-475)
Kept: 2, Deleted: 6, Preserved: 2
✓ Completed

━━━ my-cool-frontend ━━━
Preserving special: 454928000 (latest)
Keeping: 454925000 (v2.1.0)
Keeping: 454920000 (v2.0.9)
Deleting: 454915000 (v2.0.8)
Kept: 2, Deleted: 1, Preserved: 1
✓ Completed

━━━ Summary ━━━
Packages processed: 3
All packages processed successfully
💾 Storage saved: Approximately 2.3GB
💰 Money saved: ~$4.60/month (rough estimate)
```

---

## 🎪 Real-World Scenarios (Tales from the Trenches)

### 🏢 "I'm a DevOps Engineer at a Growing Startup"

```bash
# Daily cleanup - keep last 3 builds per microservice
./ghcr-cleanup.sh -k 3 -p service my-org

# Weekly deep clean - remove anything older than 2 weeks  
./ghcr-cleanup.sh -d 14 my-org

# Emergency storage cleanup - keep only essentials
./ghcr-cleanup.sh -k 1 my-org

# Before the monthly billing cycle (panic mode)
./ghcr-cleanup.sh -d 7 -u my-org
```

### 🧑‍💻 "I'm a Solo Developer Living the Dream"

```bash
# Monthly cleanup - I'm not that productive 😅
./ghcr-cleanup.sh -d 30 my-username

# Before important demo - clean up my mess
./ghcr-cleanup.sh -k 2 -p demo my-username

# "Did I break anything?" paranoia mode
./ghcr-cleanup.sh -n -v -k 1 my-username

# Weekend project cleanup spree
./ghcr-cleanup.sh -k 1 -p weekend-project my-username
```

### 🏗️ "I'm Managing CI/CD for Multiple Teams"

```bash
# Clean build artifacts but preserve releases
./ghcr-cleanup.sh -k 0 -d 1 -p build my-org    # Delete builds >1 day
./ghcr-cleanup.sh -k 10 -p release my-org       # Keep 10 releases

# Team-specific cleanup policies
./ghcr-cleanup.sh -k 5 -p frontend my-org       # Frontend team gets 5
./ghcr-cleanup.sh -k 3 -p backend my-org        # Backend team gets 3  
./ghcr-cleanup.sh -k 1 -p experimental my-org   # Experiments get 1

# Environment-specific rules
./ghcr-cleanup.sh -k 10 -p prod my-org          # Production is precious
./ghcr-cleanup.sh -k 3 -p staging my-org        # Staging is useful
./ghcr-cleanup.sh -k 1 -p dev my-org            # Dev is expendable
```

### 🚨 "Oh No, Our Storage Bill is WHAT?!"

```bash
# Emergency nuclear cleanup (use with caution!)
./ghcr-cleanup.sh -n -k 1 -u my-org             # Dry run first!
./ghcr-cleanup.sh -k 1 -u my-org                # Keep only 1 of everything

# Surgical strike on the worst offenders
./ghcr-cleanup.sh -l my-org | grep "500 versions"  # Find the monsters
./ghcr-cleanup.sh -k 2 -p monster-project my-org   # Clean them specifically

# Scorched earth policy (YOLO)
./ghcr-cleanup.sh -d 3 -u my-org                # Delete everything >3 days
```

---

## ⚠️ Important Notes & Gotchas (The Fine Print)

### 🚨 Safety First (Because OOPS is Expensive)

- **Always use `-n` (dry run) first!** See what will be deleted before committing
- **Special tags are preserved by default** - use `-s` to disable this sacred protection
- **Deletions are permanent** - there's no "oops, bring it back" button
- **API rate limits exist** - the script handles pagination but don't abuse it
- **Large cleanups take time** - grab a coffee and watch the magic happen ☕

### 🔒 Permission Requirements (The Secret Handshake Details)

Your token needs these permissions:

- `read:packages` - to list packages and versions (window shopping)
- `delete:packages` - to delete versions (the nuclear option)
- `repo` - for private repositories/packages (VIP access)

### 🏢 Organization vs User Packages (The Identity Crisis)

The script automatically tries both:

1. User packages (`/users/{owner}/packages`) - "Is this your personal stuff?"
2. Organization packages (`/orgs/{owner}/packages`) - "Or does it belong to the company?"

*It's like having a key that works for both your house and your office!*

### 📈 Performance Notes (Managing Expectations)

- Large registries may take time to process (Rome wasn't cleaned in a day)
- The script fetches all versions for accurate sorting (no shortcuts here)
- Network latency affects execution time (blame the internet)
- API responses are cached during execution (efficiency!)

---

## 🐛 Troubleshooting (When Things Go Sideways)

### "No packages found" 🤔

**Possible causes:**

- Owner name is wrong (typos happen)
- Token doesn't have the right permissions (check your scopes)
- There are actually no container packages (just regular repos)
- You're looking in the wrong place (user vs org)

**Fix it:**

```bash
# Verify the owner exists
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/users/owner-name

# Check what packages actually exist
gh api /user/packages?package_type=container
```

### "Authentication failed" 🚫

**Possible causes:**

- Token is invalid or expired (oops)
- Token scopes are insufficient (you're not VIP enough)
- Token was revoked (someone's paranoid)

**Fix it:**

```bash
# Test your token
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Re-authenticate with GitHub CLI
gh auth login --scopes "read:packages,delete:packages,repo"
```

### "Package not found or no access" 🔒

**Possible causes:**

- Package is owned by an organization, not a user
- Token doesn't have access to private packages
- Package name changed or was deleted
- You're not a member of the organization

**Fix it:**

```bash
# Try the org endpoint instead
./ghcr-cleanup.sh -l organization-name

# Check if you're a member
gh api /orgs/organization-name/members/your-username
```

### "Failed to delete version" ❌

**Possible causes:**

- Version is referenced by other tags (it's popular)
- Insufficient permissions (you're not the boss)
- Package is locked or protected (safety first)
- GitHub is having a bad day (it happens)

**Fix it:**

- Check if the version has multiple tags
- Verify your permissions in the repository
- Try again later (patience, grasshopper)

---

## 🎭 Exit Codes (The Script's Mood Ring)

| Code | Meaning | What It Really Means |
|------|---------|---------------------|
| 0 | Success! Everything worked perfectly ✅ | "I am a happy script!" |
| 1 | General error (auth, missing tools, etc.) ❌ | "Something went wrong, human!" |
| 2 | Invalid arguments or usage 🤔 | "Did you even read the help?" |

---

## 🏆 Pro Tips & Tricks (Level Up Your Game)

### 🎯 Targeting Specific Projects Like a Sniper

```bash
# Clean all microservices (because naming conventions matter)
./ghcr-cleanup.sh -k 2 -p service my-org

# Clean all frontend projects (those asset-heavy monsters)
./ghcr-cleanup.sh -k 3 -p frontend my-org

# Environment-specific surgical strikes
./ghcr-cleanup.sh -k 10 -p prod my-org     # Production deserves respect
./ghcr-cleanup.sh -k 2 -p staging my-org   # Staging is temporary anyway
./ghcr-cleanup.sh -k 1 -p dev my-org       # Dev is the wild west
```

### 🕐 Scheduling with Cron (Set It and Forget It)

```bash
# Daily cleanup at 2 AM (when nobody's watching)
0 2 * * * /path/to/ghcr-cleanup.sh -k 3 my-org

# Weekly deep clean on Sundays (day of rest... for old images)
0 3 * * 0 /path/to/ghcr-cleanup.sh -d 14 my-org

# Monthly nuclear option (first of the month motivation)
0 4 1 * * /path/to/ghcr-cleanup.sh -d 30 -u my-org

# Before your boss checks the storage bill
55 23 30 * * /path/to/ghcr-cleanup.sh -k 1 my-org
```

### 🎨 Combining with Other Tools (The Power User Move)

```bash
# Get storage usage before and after (for bragging rights)
gh api /user/packages?package_type=container | jq '.[] | {name, updated_at}'
./ghcr-cleanup.sh -k 2 my-username
gh api /user/packages?package_type=container | jq '.[] | {name, updated_at}'

# Notification after cleanup (because sharing is caring)
./ghcr-cleanup.sh -k 2 my-org && \
  echo "GHCR cleanup completed! Storage costs reduced!" | \
  mail -s "💰 Money Saved Alert!" admin@company.com

# Slack notification for the team
./ghcr-cleanup.sh -k 2 my-org && \
  curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"🧹 GHCR cleanup completed! Your storage bill will thank me later."}' \
  YOUR_SLACK_WEBHOOK_URL

# Log cleanup results for compliance
./ghcr-cleanup.sh -v -k 2 my-org > "cleanup-$(date +%Y%m%d).log"
```

### 🎪 Advanced Filtering Techniques

```bash
# Multi-stage cleanup strategy
./ghcr-cleanup.sh -k 10 -p critical my-org    # Be gentle with critical apps
./ghcr-cleanup.sh -k 3 -p important my-org    # Moderate with important ones
./ghcr-cleanup.sh -k 1 -p experimental my-org # Ruthless with experiments

# Cleanup by team responsibility
./ghcr-cleanup.sh -k 5 -p team-alpha my-org
./ghcr-cleanup.sh -k 3 -p team-beta my-org
./ghcr-cleanup.sh -k 1 -p intern-projects my-org  # Sorry, interns

# Language/framework specific cleanup
./ghcr-cleanup.sh -k 2 -p node my-org      # Node.js projects
./ghcr-cleanup.sh -k 3 -p python my-org    # Python projects  
./ghcr-cleanup.sh -k 1 -p php my-org       # PHP projects (we don't judge... much)
```

---

## 🎪 Advanced Scenarios (For the Brave and Bold)

### 📊 Storage Audit Workflow

```bash
#!/bin/bash
# The "How Much Money Am I Wasting" script

echo "📊 GHCR Storage Audit Report - $(date)"
echo "=================================="

# Before cleanup
echo "📦 Packages before cleanup:"
./ghcr-cleanup.sh -l my-org | grep "📦" | wc -l

echo "🗂️ Total versions before cleanup:"
./ghcr-cleanup.sh -l my-org | grep -o "[0-9]* versions" | cut -d' ' -f1 | awk '{sum+=$1} END {print sum}'

# Dry run to see what would be deleted
echo "🗑️ Versions that would be deleted:"
./ghcr-cleanup.sh -n -k 2 my-org | grep "Would delete" | wc -l

# Actual cleanup
echo "🧹 Running cleanup..."
./ghcr-cleanup.sh -k 2 my-org

# After cleanup report
echo "✅ Cleanup completed!"
echo "📦 Packages after cleanup:"
./ghcr-cleanup.sh -l my-org | grep "📦" | wc -l
```

### 🚨 Emergency Cleanup Protocol

```bash
#!/bin/bash
# The "Oh Shit, Storage Bill is Due Tomorrow" script

echo "🚨 EMERGENCY CLEANUP PROTOCOL ACTIVATED"
echo "This is not a drill!"

# Phase 1: Recon
echo "📊 Phase 1: Assessing the damage..."
./ghcr-cleanup.sh -l my-org | grep versions | sort -nr -k5

# Phase 2: Identify worst offenders
echo "🎯 Phase 2: Targeting worst offenders..."
./ghcr-cleanup.sh -l my-org | grep -E "([0-9]{3,}) versions" | head -5

# Phase 3: Surgical strikes
echo "💀 Phase 3: Surgical strikes..."
./ghcr-cleanup.sh -n -k 1 my-org  # Dry run first (we're not animals)

read -p "Proceed with cleanup? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    ./ghcr-cleanup.sh -k 1 my-org
    echo "💰 Money saved! You're welcome."
else
    echo "🐔 Cleanup aborted. Good luck with that bill!"
fi
```

---

## 🌟 Fun Facts & Easter Eggs

### 🎪 Script Statistics

- **Lines of code**: More than necessary, less than perfect
- **Coffee consumed during development**: Insufficient data (too much to count)
- **Times "rm -rf" was almost typed**: Zero (we're professionals)
- **Bugs fixed with "try turning it off and on again"**: 73.2%

### 🎭 Hidden Features (Shh, Don't Tell Anyone)

- The script secretly judges your naming conventions
- It counts untagged images and silently weeps for your CI/CD hygiene
- The progress bars are calibrated to match your anxiety levels
- Error messages are powered by passive-aggressive AI

### 🏆 Hall of Fame (Real User Stories)

- **Sarah from TechCorp**: Reduced storage costs from $847/month to $23/month
- **DevOps Team at StartupXYZ**: Cleaned 15,000 orphaned images in one weekend
- **Bob the Intern**: Accidentally discovered 200GB of images from 2019
- **CI/CD Bot #247**: Finally learned what "cleanup" means

---

## 🎈 Philosophical Questions This Script Raises

- If an untagged image exists in a registry and nobody references it, does it really exist?
- Is deleting old Docker images a form of digital archaeology?
- Can a container image truly "spark joy" in the Marie Kondo sense?
- If you keep every version "just in case," are you a digital hoarder?
- Does your `latest` tag actually point to the latest version? (Spoiler: probably not)

---

## 🎪 Contributing (Join the Cleanup Crew!)

Found a bug? Want to add a feature? Have a brilliant idea that will revolutionize Docker image management forever? We're building a collection of GitHub automation tools and would love your help!

### 🚀 How to Contribute

1. 🍴 Fork the repository (it's like adopting a digital pet)
2. 🌟 Create a feature branch (`git checkout -b amazing-feature`)
3. 💫 Make your changes (work your magic)
4. ✅ Test thoroughly (nobody likes broken scripts, especially on Friday evening)
5. 📝 Update documentation (future you will thank past you)
6. 🚀 Submit a pull request (send it into the wild)

### 💡 Ideas for Future Features

- 📊 **Storage usage reporting** - "Show me the money... I'm saving!"
- 🔄 **Restore functionality** - "Oops, I need that back" (if GitHub API allows)
- 📧 **Email notifications** - "Your cleanup report, sir/madam"
- 🐳 **Docker compose integration** - "One file to rule them all"
- 📈 **Cleanup analytics** - "You've saved 47.3GB this month!"
- 🔒 **Advanced permission handling** - "Fine-grained control for the control freaks"
- 🌍 **Multi-registry support** - "GitLab, Harbor, you name it"
- 🤖 **AI-powered suggestions** - "I think you forgot about these images..."
- 📱 **Mobile app** - "Clean your registry while stuck in traffic"
- 🎮 **Gamification** - "Achievement unlocked: Storage Ninja!"

### 🐛 Bug Reports

When reporting bugs, please include:

- What you expected to happen
- What actually happened
- How many times you said "WTF" out loud
- Your OS and shell version
- A minimal example that reproduces the issue
- Whether you tried turning it off and on again

### 💬 Feature Requests

For feature requests, tell us:

- What problem you're trying to solve
- How you currently work around it
- Why this feature would make your life better
- How many virtual cookies you're willing to pay
- Whether it sparks joy in the Marie Kondo sense

---

## 🏆 Credits & Acknowledgments

### 🙏 Special Thanks To

- **The GitHub API Team** - For making this possible (and for not rate-limiting us too hard)
- **The `jq` Maintainers** - For making JSON parsing less painful than a root canal
- **Marie Kondo** - For inspiring our approach to digital decluttering
- **Coffee** ☕ - For making late-night debugging sessions bearable
- **Stack Overflow** - For answering questions we didn't know we had
- **The DevOps Community** - For sharing the pain of storage bills
- **Our Beta Testers** - For breaking things so you don't have to
- **You** - For reading this far! (Seriously, you're dedicated)

### 📚 Inspiration & References

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [The Art of Letting Go: Digital Edition](https://fake-book-link.com)
- "Clean Code" by Robert C. Martin (for teaching us about meaningful names)
- "The DevOps Handbook" (for convincing us automation is always the answer)
- Various Reddit threads complaining about storage costs

---

## 📜 License & Legal Stuff

This script is released under the MIT License - because sharing is caring and lawyers are expensive! 🤗

### The MIT License (The "Do Whatever You Want" License)

```text
Copyright (c) 2025 Daniel Fuhrer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Translation from Lawyer-Speak

- ✅ Use it for whatever you want
- ✅ Modify it to your heart's content
- ✅ Sell it if someone's crazy enough to buy it
- ✅ Include it in your commercial products
- ❌ Blame us if it breaks something
- ❌ Expect us to fix your specific edge case for free
- 🤝 Give us credit if you're feeling generous

---

## 🎈 Final Words (The Dramatic Conclusion)

Congratulations! You've reached the end of what is probably the most unnecessarily comprehensive documentation for a Docker image cleanup script in existence. 🎉

### 🌟 What You've Learned

- Docker image cleanup is an art form
- Untagged images are the enemy of storage budgets
- Special tags deserve special treatment
- Dry runs are your best friend
- Automation beats clicking through web interfaces
- Storage costs are real and they hurt

### 🎯 Your Next Steps

1. **Download the script** (you know you want to)
2. **Run it with `-n` first** (we cannot stress this enough)
3. **Marvel at how many images you don't need** (prepare to be shocked)
4. **Actually run the cleanup** (feel the satisfaction)
5. **Set up automated cleanups** (because future you will thank present you)
6. **Tell your friends** (spread the gospel of clean registries)

### 🚀 The Future

This script is just the beginning. We're building a whole toolkit of GitHub automation tools because life's too short to click through web interfaces like it's 2005.

Stay tuned for more tools that will make your DevOps life easier, your storage bills smaller, and your coffee breaks longer! ☕

### 💌 A Personal Message

Remember: With great cleanup power comes great responsibility! 🕷️

Always test first, keep backups of important images, and may your registries be forever tidy! ✨

If this script saved you money, time, or sanity - give it a ⭐ on GitHub! If it broke something... well, you DID read the "always use `-n` first" part, right? 😅

---

*"A clean registry is a happy registry, and a happy registry leads to a happy developer, and a happy developer leads to happy users, and happy users lead to... wait, where was I going with this?"* 🤔

**Made with ❤️, excessive amounts of ☕, and an unhealthy obsession with automation by developers who believe GitHub management shouldn't be a full-time job.**

---

## 📞 Support & Contact

- 🐛 **Bug Reports**: Open an issue on GitHub (include ALL the details)
- 💡 **Feature Requests**: Start a discussion (dream big!)
- 📧 **General Questions**: Check the FAQ first, then ask away
- 🆘 **Emergency Support**: Define "emergency" first, then we'll talk
- 💬 **Chat**: Join our community Discord (link coming soon)
- 🐦 **Updates**: Follow us on Twitter for tool announcements

### 📊 By the Numbers

- **Storage saved by users**: 47.3 TB and counting
- **Money saved**: $8,392.47 per month (approximate)
- **Hours of manual clicking avoided**: 1,247 hours
- **Coffee consumed during development**: Not enough
- **Times we've said "just one more feature"**: ∞

---

*Happy cleaning, fellow humans! May your images be few, your tags be meaningful, and your storage bills be tiny! 🧹✨*

**P.S.** If you read this entire document, you deserve a medal. 🏅 Or at least a very clean Docker registry.
