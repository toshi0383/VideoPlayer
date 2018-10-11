# VideoPlayer
![Xcode](https://img.shields.io/badge/Xcode-10.0-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)

AVPlayer control made easy.

![design](https://github.com/toshi0383/assets/blob/master/VideoPlayer/VideoPlayer-en.png?raw=true)

```
VideoPlayer
- VideoPlayerControl
- VideoPlayerMonitor
```

# Usage
## Initializing AVPlayer
Observe `VideoPlayer.player: Single<AVPlayer>` to get created AVPlayer immediately after initialization.

See: [Example](Example/)

## Monitor and Control state
TBD

See: [Example](Example/)

## Handling Errors
TBD

See: [Example](Example/)

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
