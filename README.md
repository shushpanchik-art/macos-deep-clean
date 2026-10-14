# macOS Deep Clean

🧹 Universal deep cleaning script for macOS. Frees up space by removing caches, orphaned app data, logs, and more.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)

## 🎯 Features

- **Smart Cache Cleanup** — Removes large app caches (>100MB) while preserving critical system caches
- **Orphan Detection** — Finds and removes leftover data from deleted applications
- **Safe by Default** — Never touches user documents, photos, or active applications
- **Multiple Modes** — Quick, deep, or targeted cleaning
- **Detailed Reports** — Shows exactly what was cleaned and how much space was freed
- **Zero Configuration** — Works out of the box

## 📊 Results

Real-world example:
- **First run:** 5-20 GB freed
- **Monthly maintenance:** 2-10 GB freed
- **Weekly quick clean:** 500MB-2GB freed

Based on actual usage: **162 GB freed** from a production system.

## 🚀 Installation

### One-line install:

```bash
curl -fsSL https://raw.githubusercontent.com/shushpanchik-art/macos-deep-clean/main/install.sh | bash
```

### Manual install:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/shushpanchik-art/macos-deep-clean/main/macos-deep-clean.sh
chmod +x macos-deep-clean.sh

# Add alias to your shell
echo "alias clean='~/macos-deep-clean.sh'" >> ~/.zshrc
source ~/.zshrc
```

## 💻 Usage

```bash
clean              # Full deep clean (recommended)
clean --quick      # Fast clean (caches + trash only)
clean --orphans    # Find and remove orphaned app data
clean --purge      # Memory purge only
clean --help       # Show help
```

## 🔍 What Gets Cleaned

### ✅ Safe to Remove

| Category | What | Typical Size |
|----------|------|--------------|
| **App Caches** | Large app caches (>100MB) | 2-10 GB |
| **Orphans** | Leftover data from deleted apps | 5-50 GB |
| **Logs** | Old system/app logs (>7 days) | 100-500 MB |
| **Downloads** | Old installers (.dmg, .pkg >30 days) | Varies |
| **Trash** | ~/.Trash contents | Varies |
| **Xcode** | DerivedData, old Archives | 10-50 GB |
| **Homebrew** | Old formula versions, caches | 500MB-2GB |

### ❌ Never Touches

- ✅ User documents
- ✅ Photos, Music, Videos
- ✅ Critical system caches (dyld, Metal, CloudKit)
- ✅ Active applications
- ✅ iCloud data

## 📋 Modes

### Full Clean (Default)
```bash
clean
```
Performs all cleanup operations. **Run monthly.**

### Quick Clean
```bash
clean --quick
```
Only caches, trash, and memory purge. **Run weekly.**

### Orphans Only
```bash
clean --orphans
```
Finds leftover data from deleted apps. **Run after uninstalling multiple apps.**

### Memory Purge
```bash
clean --purge
```
Frees up RAM. **Run before heavy tasks (video editing, ML training).**

## 🛡️ Safety

- **No sudo required** for basic operations
- **Asks for confirmation** on system-level changes
- **Creates reports** of everything removed
- **Logs all operations** to `~/.macos-cleanup.log`
- **Open source** — audit the code yourself

## 📊 Reports

Every run generates a detailed report:

```bash
# View last report
ls -lt /tmp/cleanup-report-* | head -1 | xargs cat

# View all cleanup history
cat ~/.macos-cleanup.log
```

## 🔧 Requirements

- macOS 10.15 (Catalina) or later
- Bash 3.2+ (included in macOS)
- Optional: Homebrew (for brew cleanup)
- Optional: Xcode (for Xcode cleanup)

## 📖 Examples

### Regular Maintenance
```bash
# Weekly quick clean
clean --quick

# Monthly deep clean
clean

# After uninstalling apps
clean --orphans
```

### Before Heavy Tasks
```bash
# Free up memory before ML training
clean --purge
```

### Combo with Other Tools
```bash
# Clean before system update
clean && softwareupdate -i -a
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## ⭐ Show Your Support

If this script saved you disk space, give it a star! ⭐

## 🔗 Related Projects

- [LLM Performance Mode](https://github.com/shushpanchik-art/macos-llm-mode) — Optimize macOS for local LLM training
- [homebrew-cleanup](https://github.com/Homebrew/brew) — Official Homebrew cleanup

## 📮 Contact

- GitHub: [@shushpanchik-art](https://github.com/shushpanchik-art)
- Issues: [GitHub Issues](https://github.com/shushpanchik-art/macos-deep-clean/issues)

---

**Made with ❤️ for the macOS community**

*Based on real-world experience cleaning a production system and freeing 162 GB of disk space.*
