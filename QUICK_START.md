# 🚀 Quick Start Guide - Get Running in 2 Minutes

## Problem: No Xcode Project File

You're seeing the Swift source code but **no `.xcodeproj` file** to open in Xcode. Here are **3 ways** to get started:

---

## ✅ Option 1: Create Xcode Project (RECOMMENDED - 2 minutes)

### Step 1: Create New Xcode Project
1. Open **Xcode**
2. Click **Create New Project**
3. Choose **iOS → App**
4. Settings:
   - Product Name: `EndlessRunner`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Organization Identifier: `com.yourname`
5. Save **outside this repository** (e.g., Desktop)

### Step 2: Replace Files
1. In Xcode Project Navigator, **delete**:
   - `ContentView.swift`
   - `EndlessRunnerApp.swift` (if it exists)

2. **Drag and drop** the entire `Sources/EndlessRunner/` folder from this repository into your Xcode project
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Add to target: EndlessRunner

3. **Copy** `Info.plist` from `Sources/EndlessRunner/Info.plist` to your project

### Step 3: Configure
1. Select your project → Target → **General**
2. **Deployment Info**:
   - Supported Destinations: **iPhone**
   - Device Orientation: ✅ Landscape Left, ✅ Landscape Right (uncheck Portrait)

### Step 4: Build & Run
- Press **⌘R**
- Select iPhone simulator
- Game should launch in landscape mode! 🎮

---

## ✅ Option 2: Use Xcode Command Line (If you have Xcode installed)

Run this script from the repository root:

```bash
# Create Xcode project using command line
cd /path/to/Endlessrunner

# This will open Xcode with the Swift files
open Package.swift
```

Then in Xcode:
- File → New → Project → iOS App
- Follow Option 1 steps above

---

## ✅ Option 3: Download Pre-Made Xcode Project Template

I can create a complete `.xcodeproj` file for you. Would you like me to:

1. Generate the Xcode project configuration files?
2. Create a script to automate project setup?
3. Provide a different project structure?

---

## 🔍 What You Should See in Xcode

Once opened, your Project Navigator should look like:

```
EndlessRunner/
├── 📁 Views/
│   ├── ContentView.swift
│   └── GameView.swift
├── 📁 Managers/
│   ├── GameManager.swift
│   ├── ShapeTextureManager.swift
│   └── LevelGenerator.swift
├── 📁 GameEngine/
│   ├── GameScene.swift
│   ├── 📁 Components/ (5 files)
│   ├── 📁 Entities/ (2 files)
│   └── 📁 Systems/ (1 file)
├── 📁 Utilities/
│   └── ObjectPool.swift
├── EndlessRunnerApp.swift
└── Info.plist
```

---

## ⚠️ Why No .xcodeproj in GitHub?

Xcode project files (`.xcodeproj`) are:
- **Binary/XML hybrids** - Hard to create manually
- **UUID-heavy** - Contain hundreds of unique identifiers
- **Merge conflicts** - Terrible for version control

That's why we provide:
- ✅ **Source code** (ready to import)
- ✅ **Swift Package** (Package.swift - text-based)
- ✅ **Clear instructions** (this guide)

---

## 🆘 Troubleshooting

### "Cannot find 'GameManager' in scope"
**Fix**: Ensure all files are added to the target:
1. Select each `.swift` file
2. File Inspector (⌥⌘1)
3. Target Membership → ✅ EndlessRunner

### "Module 'GameplayKit' not found"
**Fix**: Add framework:
1. Project → Target → General
2. Frameworks, Libraries → Click **+**
3. Search "GameplayKit" → Add

### Still having issues?
Let me know and I can:
- Generate actual Xcode project files
- Create an automated setup script
- Provide alternative project structure

---

## 📺 Video Alternative

If you prefer visual instructions, the process is:
1. **Xcode → New → iOS App → SwiftUI**
2. **Drag `Sources/EndlessRunner/` into project**
3. **⌘R to run**

That's it! 🚀
