import AVFoundation
import RxCocoa
import RxSwift

/// Create an AVPlayer instance and emit via Single,
/// while setting up monitor and control module.
///
/// NOTE: Make sure the lifecycle of this class is synced with the player instance.
public final class VideoPlayerManager {

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

    /// - parameter url: playlist URL
    /// - parameter control: You should keep this instance, just like you do in real life with TV remote.
    /// - parameter factory: Mock and DI this protocol instance to mock player creation and states.
    ///      seealso: MockVideoPlayerFactory
    public init(url: URL,
                control: VideoPlayerControl,
                factory: VideoPlayerFactoryType = VideoPlayerFactory()) {

        self.monitor = VideoPlayerMonitor()
        self.control = control

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = factory.loadAsset(asset)
            .map { factory.initVideoPlayer(playerItem) }

            /// NOTE: KVO should be registerd from main-thread
            .observeOn(ConcurrentMainScheduler.instance)

            .do(onNext: { [weak monitor, weak playerDisposeBag] videoPlayer in
                guard let monitor = monitor,
                    let playerDisposeBag = playerDisposeBag else { return }

                videoPlayer.stream.rate
                    .bind(to: monitor.rate)
                    .disposed(by: playerDisposeBag)

                Observable.combineLatest(videoPlayer.stream.playerItemStatus, control.setRate)
                    .filter { $0.0 == .readyToPlay }
                    .map { $1 }
                    .bind(to: videoPlayer.stream.setRate)
                    .disposed(by: playerDisposeBag)
            })
            .map { $0.player }
            .asSingle()
    }
}

// MARK: VideoPlayerFactory

public protocol VideoPlayerFactoryType {
    func loadAsset(_ asset: AVURLAsset) -> Observable<Void>
    func initVideoPlayer(_ playerItem: AVPlayerItem) -> VideoPlayerType
}

public final class VideoPlayerFactory: VideoPlayerFactoryType {
    public func loadAsset(_ asset: AVURLAsset) -> Observable<Void> {
        return asset.rx.isPlayable.filter { $0 }.map { _ in }.take(1)
    }

    public func initVideoPlayer(_ playerItem: AVPlayerItem) -> VideoPlayerType {
        return VideoPlayer(playerItem: playerItem)
    }

    public init() { }
}

// MARK: VideoPlayer

public protocol VideoPlayerType {
    var player: AVPlayer { get }
    var stream: VideoPlayerStream { get }
}

/// AVPlayer wrapper
///
/// - Note: Disposed after right after player initalization via Single.
public final class VideoPlayer: VideoPlayerType {
    public let player: AVPlayer
    public let stream: VideoPlayerStream
    private let disposeBag = DisposeBag()

    public init(playerItem: AVPlayerItem) {
        self.player = AVPlayer(playerItem: playerItem)
        self.stream = VideoPlayerStream(rate: player.rx.rate,
                                        playerItemStatus: playerItem.rx.status)

        self.stream.setRate
            .bind(to: player.rx.setRate)
            .disposed(by: player.rx.disposeBag)
    }
}

// MARK: VideoPlayerStream

public final class VideoPlayerStream {
    let rate: Observable<Float>
    let playerItemStatus: Observable<AVPlayerItem.Status>
    let setRate = PublishRelay<Float>()

    public init(rate: Observable<Float>,
                playerItemStatus: Observable<AVPlayerItem.Status>) {
        self.rate = rate
        self.playerItemStatus = playerItemStatus
    }
}

// MARK: VideoPlayerMonitor

/// Player Monitor
public final class VideoPlayerMonitor {

    /// NOTE: Does not `replay`.
    ///   AVPlayer.rate is also updated by the SDK.
    public let rate = PublishRelay<Float>()
}

// MARK: VideoPlayerControl

/// Player Controller
public final class VideoPlayerControl {
    public let setRate: BehaviorRelay<Float>

    /// - parameter rate: set 0.0 if you prefer player to be paused initially.
    public init(rate: Float = 1.0) {
        self.setRate = BehaviorRelay<Float>(value: rate)
    }
}
