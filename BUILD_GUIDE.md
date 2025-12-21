# Build Guide: Endless Runner

This guide walks you through setting up and building the Endless Runner project in Xcode.

## Quick Start (5 minutes)

### Step 1: Create Xcode Project

1. Open **Xcode**
2. Select **File → New → Project** (⌘⇧N)
3. Choose **iOS → App**
4. Configure:
   - **Product Name**: `EndlessRunner`
   - **Team**: (Your development team)
   - **Organization Identifier**: `com.yourname` (or any identifier)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: None (default)
   - **Use Core Data**: ❌ Unchecked
   - **Include Tests**: ✅ Optional
5. Click **Next**, choose save location (this repository folder)

### Step 2: Configure Project Structure

1. In Xcode's Project Navigator (left sidebar), **delete** the default files:
   - `ContentView.swift` (we have a custom version)
   - Any default assets

2. **Add our source files**:
   - Drag the entire `EndlessRunner/EndlessRunner` folder from Finder into Xcode
   - When prompted:
     - ✅ **Copy items if needed**: Checked
     - ✅ **Create groups**: Selected
     - ✅ **Add to targets**: EndlessRunner (checked)

Your project structure should look like:
```
EndlessRunner/
├── EndlessRunnerApp.swift
├── Info.plist
├── Views/
│   ├── ContentView.swift
│   └── GameView.swift
├── Managers/
├── GameEngine/
└── Utilities/
```

### Step 3: Configure Build Settings

1. Select **EndlessRunner** project in Navigator
2. Select **EndlessRunner** target
3. Go to **General** tab:
   - **Deployment Info**:
     - iOS: `17.0` (minimum)
     - Device Orientation: ✅ Landscape Left, ✅ Landscape Right
     - ❌ Portrait (uncheck)
   - **Info.plist**: Ensure it points to `EndlessRunner/Info.plist`

4. Go to **Build Settings** tab:
   - Search for "Swift Language Version"
   - Set to: **Swift 6** (or latest available)

### Step 4: Build and Run

1. Select your target device/simulator (iPhone 15 recommended)
2. Press **⌘R** (or click the Play button)
3. App should launch in landscape mode with the menu screen

## Project Configuration Details

### Required Frameworks
These should be auto-linked, but verify in **General → Frameworks, Libraries**:
- ✅ SwiftUI.framework
- ✅ SpriteKit.framework
- ✅ GameplayKit.framework
- ✅ UIKit.framework

### Info.plist Key Settings

The provided `Info.plist` configures:
- **Landscape-only orientation**: Optimal for side-scroller gameplay
- **Full screen required**: Maximizes play area
- **Status bar hidden**: Eliminates distractions

### Swift Compiler Settings

If you encounter concurrency warnings, add to **Build Settings → Other Swift Flags**:
```
-strict-concurrency=complete
```

This ensures proper actor isolation for the `LevelGenerator`.

## Troubleshooting

### Issue: "Cannot find type 'GameEntity' in scope"

**Solution**: Ensure all files in `GameEngine/` are added to the target:
1. Select each `.swift` file in Navigator
2. Right-click → **Show File Inspector** (⌥⌘1)
3. Verify **Target Membership** includes "EndlessRunner" (checked)

### Issue: "Module 'GameplayKit' not found"

**Solution**: Add framework manually:
1. Select project → Target → **General**
2. Scroll to **Frameworks, Libraries, and Embedded Content**
3. Click **+**, search for "GameplayKit", add

### Issue: Landscape mode not enforced

**Solution**: Check `Info.plist`:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

Remove any Portrait entries.

### Issue: Low performance (< 60 FPS)

**Debug Checklist**:
1. Check **SKView** settings in `GameView.swift`:
   ```swift
   skView.preferredFramesPerSecond = 60  // Or 120 for ProMotion
   skView.isAsynchronous = true
   ```

2. Verify shape textures are cached (should see < 10 draw calls in debug HUD)

3. Profile with **Instruments** (⌘I):
   - Template: **Game Performance**
   - Look for CPU hotspots in `update(_:)`

## Running on Device

### Requirements
- Apple Developer Account (free tier works)
- iOS device with iOS 17+

### Steps
1. Connect device via USB
2. **Xcode → Preferences → Accounts**: Add Apple ID
3. **Project → Signing & Capabilities**:
   - Team: (Select your account)
   - Bundle Identifier: Must be unique (e.g., `com.yourname.endlessrunner`)
4. Trust certificate on device: **Settings → General → Device Management**
5. Build and run (⌘R)

## Testing the Architecture

### Verify ECS System
1. Run the game
2. Pause after 10 seconds
3. Open **Debug Navigator** (⌘7)
4. Check memory usage: Should be stable (~50MB)

### Verify Object Pooling
Add debug logging in `ObjectPool.swift`:
```swift
func spawn() -> T {
    print("Pool stats: \(poolStats)")
    // ...
}
```

You should see `inactive` count decrease as obstacles spawn, then increase as they despawn.

### Verify Shape Caching
In `ShapeTextureManager.swift`:
```swift
func texture(for shapeType: ShapeType, color: SKColor, size: CGSize? = nil) -> SKTexture {
    let key = cacheKey(...)
    if let cached = cache[key] {
        print("✅ Cache hit for \(key)")
        return cached
    }
    print("❌ Cache miss for \(key) - generating")
    // ...
}
```

First run should show misses, subsequent spawns should show hits.

## Advanced Configuration

### Enable ProMotion (120 FPS)
In `GameView.swift`:
```swift
skView.preferredFramesPerSecond = 120
```

Only works on iPhone 13 Pro+ devices.

### Adjust Difficulty Curve
Edit `LevelGenerator.swift`:
```swift
private func updateDifficulty(distance: Double) {
    if distance > 500 {  // Changed from 2000
        currentDifficulty = .hard
    }
    // ...
}
```

### Add More Shapes
In `ShapeTextureManager.swift`, add to `ShapeType` enum:
```swift
enum ShapeType: String {
    case square, circle, triangle, diamond, hexagon, star
    case octagon  // New!
}
```

Then implement in `createShapeNode(type:color:size:)`.

## Distribution

### TestFlight
1. **Archive**: Product → Archive (⌘⇧B with "Any iOS Device" selected)
2. **Distribute**: Xcode Organizer → Distribute App
3. Upload to App Store Connect
4. Add testers in TestFlight dashboard

### Export IPA
1. Archive the app
2. Organizer → Distribute → **Ad Hoc**
3. Share `.ipa` file (requires device UDIDs registered)

## Next Steps

After successful build:
1. Read `ARCHITECTURE.md` for deep technical details
2. Review `README.md` for feature list
3. Experiment with adding new obstacle types
4. Profile performance using Instruments

Happy coding! 🚀
