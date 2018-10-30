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

# Features (Including Example)

work in progress

- [x] Play/Pause
- [x] Seek
- [x] Background Playback
- [x] Background AirPlay
- [x] Built-in player MonitorView for debugging
- [x] allows recording or not (defaults to no)
- [x] fundamental player state observables (e.g. rate, periodicTime, duration..)
- [ ] any loading state observable
- [ ] Cross-viewcontroller AirPlay (will be in Example soon)
- [ ] Picture-in-Picture (will be in Example soon)

# Usage
## Initializing AVPlayer
Observe `VideoPlayer.player: Single<AVPlayer>` to get AVPlayer instance.

See: [Example](Example/)

## Monitor and Control state

Do not write `player?.pause()` any more.

See: [Example](Example/)

## Encrypted contents

`VideoPlayerFactory` initializer accepts `AVAssetResourceLoaderDelegate`.
Set your instance which handles `EXT-X-KEY` methods.

## Handling Errors
TBD

See: [Example](Example/)

## Testing

See: [VideoPlayerTests](VideoPlayerTests/)

You can simulate player behavior by yourself to improve test coverage of your app.

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
