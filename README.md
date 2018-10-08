# RxAVPlayer
![Xcode](https://img.shields.io/badge/Xcode-10.0-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)

AVPlayer control made easy.

```
VideoPlayerManager
- VideoPlayerControl
- VideoPlayerMonitor
```

# Usage
## Initializing AVPlayer
TBD
Observe `VideoPlayerManager.player: Single<AVPlayer>` to get created valid AVPlayer.
See: [[Example]]

## Monitor and control state
TBD
See: [[Example]]

## Handling Errors
TBD
See: [[Example]]

# Build
1. Make sure your default `xcode-select -p` points at correct Xcode version.

2. Run following
   ```
   carthage bootstrap --platform iOS
   xcodegen
   ```

3. Open generated xcodeproj

# License
MIT
