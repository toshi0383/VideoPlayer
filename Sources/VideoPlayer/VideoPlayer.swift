import AVFoundation
import RxCocoa
import RxSwift

/// Create an AVPlayer instance and emit via Single,
/// while setting up monitor and control module.
///
/// NOTE: Make sure the lifecycle of this class is synced with the player instance.
public final class VideoPlayer {

    /// Emits and cache AVPlayer once initialized.
    /// Note that `Single` does not replay value.
    public let player: Single<AVPlayer>

    /// Controls player state
    public let control: VideoPlayerControl

    /// Monitors player state
    public let monitor: VideoPlayerMonitor

    /// Use this bag if you need your observable to be in sync with player lifecycle.
    public let playerDisposeBag = DisposeBag()

    /// Append anything which you need to sync lifecycle with player.
    /// e.g. QoE Object
    public var objects: [Any] = []

    /// Initializes VideoPlayer
    ///
    /// - parameter url: playlist URL
    /// - parameter control: You should keep this instance, just like you do in real life with TV remote.
    /// - parameter factory: Mock and DI this protocol instance to mock player creation and states.
    ///      seealso: MockVideoPlayerFactory
    /// - developer note: NOT allowed to touch raw AVPleyer instance.
    public init(url: URL,
                control: VideoPlayerControl,
                factory: VideoPlayerFactoryType = VideoPlayerFactory()) {

        self.monitor = VideoPlayerMonitor()
        self.control = control

        player = factory.makeVideoPlayer(AVPlayerItem(asset: AVURLAsset(url: url)),
                                         playerDisposeBag: playerDisposeBag)

            /// NOTE: KVO should be registerd from main-thread
            ///   https://developer.apple.com/documentation/avfoundation/avplayer
            .observeOn(ConcurrentMainScheduler.instance)

            .do(onNext: { [weak monitor, weak playerDisposeBag] videoPlayer in
                guard let monitor = monitor,
                    let playerDisposeBag = playerDisposeBag else { return }

                let stream = videoPlayer.stream

                stream.rate
                    .bind(to: monitor._rate)
                    .disposed(by: playerDisposeBag)

                Observable.combineLatest(stream.playerItemStatus, control.setRate)
                    .filter { $0.0 == .readyToPlay }
                    .map { $1 }
                    .bind(to: stream.setRate)
                    .disposed(by: playerDisposeBag)

                stream.isExternalPlaybackActive
                    .bind(to: monitor._isAirPlaying)
                    .disposed(by: playerDisposeBag)

                stream.isPlayerSeeking
                    .bind(to: monitor._isPlayerSeeking)
                    .disposed(by: playerDisposeBag)

                let isPlayable = stream.isPlayable
                let playerItemStatus = stream.playerItemStatus

                let isPlayableAndReadyToPlay = Observable.combineLatest(isPlayable,
                                                                        playerItemStatus)
                    .map { $0.0 && $0.1 == .readyToPlay }
                    .distinctUntilChanged()
                    .share(replay: 1)

                let endPosition = stream.seekableTimeRanges
                    .map { seekableTimeRanges -> CMTime? in
                        guard let seekableLastTimeRanges = seekableTimeRanges.last else { return nil }

                        let seekableLastTimeRangeValue = seekableLastTimeRanges.timeRangeValue
                        guard seekableLastTimeRangeValue != kCMTimeRangeInvalid
                            && seekableLastTimeRangeValue != kCMTimeRangeZero else { return nil }

                        let endPosition = seekableLastTimeRangeValue.start + seekableLastTimeRangeValue.duration
                        guard endPosition.seconds > 0 else { return nil }

                        return endPosition
                    }
                    .filterNil()

                let isSeekable = Observable.combineLatest(isPlayableAndReadyToPlay, endPosition)
                    .map { $0 && $1.isValid && !$1.isIndefinite } // Indefinite is duration of a live broadcast
                    .distinctUntilChanged()
                    .share(replay: 1)

                #warning("FIXME: assetDuration for VOD contents")
                let duration = endPosition.share(replay: 1, scope: .whileConnected)

                #warning("FIXME: not necessary for LIVE contents")
                Observable.combineLatest(isSeekable, control.seekTo.asObservable())
                    .map { $0.0 ? $0.1 : nil }
                    .filterNil()
                    .withLatestFrom(duration) { ($0, $1) }
                    .map { args in
                        let (time, duration) = args

                        return time.seconds >= 0
                            ? CMTime(seconds: time.seconds, preferredTimescale: duration.timescale)
                            : CMTime(seconds: -1, preferredTimescale: duration.timescale)
                    }
                    .bind(to: stream.requestSeekTo)
                    .disposed(by: playerDisposeBag)
            })
            .map { $0.player }
            .asSingle()
    }
}

// MARK: VideoPlayerFactory

/// VideoPlayer will use this to get VideoPlayer instance.
public protocol VideoPlayerFactoryType {
    func makeVideoPlayer(_ playerItem: AVPlayerItem, playerDisposeBag: DisposeBag) -> Observable<AVPlayerWrapperType>
}

public final class VideoPlayerFactory: VideoPlayerFactoryType {

    public final class Configuration {
        let enableAirPlay: Bool

        public init(enableAirPlay: Bool = false) {
            self.enableAirPlay = enableAirPlay
        }
    }

    public let assetResourceLoaderDelegate: AVAssetResourceLoaderDelegate?

    private let configuration: Configuration

    public func makeVideoPlayer(_ playerItem: AVPlayerItem,
                                playerDisposeBag: DisposeBag) -> Observable<AVPlayerWrapperType> {
        if let delegate = assetResourceLoaderDelegate {
            (playerItem.asset as? AVURLAsset)?.resourceLoader
                .setDelegate(delegate, queue: .global(qos: .default))
        }

        return playerItem.asset.rx.isPlayable
            .filter { $0 }
            .take(1)

            // NOTE: strongly captures self
            //   VideoPlayerFactory is deallocated right after makeVideoPlayer is called,
            //   therefore self would be nil if it's a weak ref.
            .map { _ in
                AVPlayerWrapper(playerItem: playerItem,
                                enableAirPlay: self.configuration.enableAirPlay,
                                playerDisposeBag: playerDisposeBag)
            }
    }

    public init(configuration: Configuration = .init(),
                assetResourceLoaderDelegate: AVAssetResourceLoaderDelegate? = nil) {
        self.configuration = configuration
        self.assetResourceLoaderDelegate = assetResourceLoaderDelegate
    }
}

// MARK: VideoPlayer

public protocol AVPlayerWrapperType {
    var player: AVPlayer { get }
    var stream: VideoPlayerStream { get }
}

/// AVPlayer wrapper
/// Allowed to touch raw AVPlayer instance.
/// Responsible for binding player state to VideoPlayerStream and vice-versa.
///
/// - Note: Disposed right after player initalization via Single.
public final class AVPlayerWrapper: AVPlayerWrapperType {

    public let player: AVPlayer
    public let stream: VideoPlayerStream

    public init(playerItem: AVPlayerItem,
                enableAirPlay: Bool,
                playerDisposeBag: DisposeBag,
                notification: NotificationCenter = .default) {

        self.player = AVPlayer(playerItem: playerItem)
        self.player.usesExternalPlaybackWhileExternalScreenIsActive = enableAirPlay

        func currentTime() -> Observable<CMTime> {
            return .create { [weak playerItem] observer in
                func observable() -> Observable<CMTime> {
                    guard let playerItem = playerItem else {
                        return .empty()
                    }
                    return .just(playerItem.currentTime())
                }
                return observable().bind(to: observer)
            }
        }

        guard let asset = playerItem.asset as? AVURLAsset else {
            fatalError("`playerItem.asset` must be an AVURLAsset instance.")
        }

        let playerError = playerItem.rx.anyError(with: notification)

        self.stream = VideoPlayerStream(isPlayable: asset.rx.isPlayable,
                                        assetDuration: asset.rx.duration,
                                        playerItemStatus: playerItem.rx.status,
                                        seekableTimeRanges: playerItem.rx.seekableTimeRanges,
                                        timedMetadata: playerItem.rx.timedMetadata,
                                        currentTime: currentTime(),
                                        rate: player.rx.rate,
                                        isExternalPlaybackActive: player.rx.isExternalPlaybackActive,
                                        setPreferredPeakBitrate: { [weak playerItem] bitrate in
                                            playerItem?.preferredPeakBitRate = bitrate
                                        },
                                        setVolume: { [weak player] volume in
                                            player?.volume = volume
                                        },
                                        seekTo: { seekTo -> Observable<Bool> in
                                            return Observable.create { [weak playerItem] observer in
                                                playerItem?.seek(to: seekTo, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { finished in

                                                    // Note:
                                                    //   We don't know if `finished: false` means that either
                                                    //   current seek is cancelled or being interrupted by other seek.

                                                    observer.onNext(finished)
                                                    observer.onCompleted()
                                                })

                                                return Disposables.create()
                                            }
                                            .startWith(true)
                                            .map { _ in false }
                                        },
                                        setRate: { [weak player] rate in
                                            player?.rate = rate
                                        },
                                        didPlayToEndTime: notification.rx
                                            .notification(.AVPlayerItemDidPlayToEndTime, object: playerItem)
                                            .map(void),
                                        playerError: playerError,
                                        playerDisposeBag: playerDisposeBag)
    }
}

// MARK: VideoPlayerMonitor

/// Player Monitor
public final class VideoPlayerMonitor {

    /// NOTE: Does not `replay`.
    ///   AVPlayer.rate is also updated by the SDK.
    public let rate: Observable<Float>
    public let isPlayerSeeking: Observable<Bool>
    public let isAirPlaying: Observable<Bool>

    internal let _rate = PublishRelay<Float>()
    internal let _isPlayerSeeking = BehaviorRelay<Bool>(value: false)
    internal let _isAirPlaying = BehaviorRelay<Bool>(value: false)

    internal init() {
        rate = _rate.asObservable()
        isPlayerSeeking = _isPlayerSeeking.asObservable()
        isAirPlaying = _isAirPlaying.asObservable()
    }

    internal var consoleString: Observable<String> {
        return Observable
            .combineLatest(rate.map { "rate: \($0)" },
                           isPlayerSeeking.map { "isPlayerSeeking: \($0)" },
                           isAirPlaying.map { "isAirPlaying: \($0)" })
            .map { [$0, $1, $2].joined(separator: "\n") }
    }
}

// MARK: VideoPlayerControl

/// Player Controller
public final class VideoPlayerControl {
    public let setRate: BehaviorRelay<Float>
    public let seekTo: BehaviorRelay<CMTime>

    /// - parameter rate: set 0.0 if you prefer player to be paused initially.
    /// - parameter seekTO: initial seek position to start playback
    public init(rate: Float = 1.0,
                seekTo: CMTime = CMTime(seconds: 0, preferredTimescale: 1)) {
        self.setRate = BehaviorRelay(value: rate)
        self.seekTo = BehaviorRelay(value: seekTo)
    }
}
