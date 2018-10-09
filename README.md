# VideoPlayerManager
![Xcode](https://img.shields.io/badge/Xcode-10.0-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)

AVPlayer control made easy.

![design]()

```
VideoPlayerManager
- VideoPlayerControl
- VideoPlayerMonitor
```

# Usage
## Initializing AVPlayer
TBD
Observe `VideoPlayerManager.player: Single<AVPlayer>` to get created AVPlayer immediately after initialization.
See: [[Example]]

## Monitor and Control state
TBD
See: [[Example]]

## Handling Errors
TBD
See: [[Example]]

# Build Example
1. Make sure your default `xcode-select -p` points at correct Xcode version.

2. Run following
   ```
   carthage bootstrap --platform iOS
   xcodegen
   ```

3. Open `Example.xcodeproj`

# License
MIT
