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

    public let control: VideoPlayerControl
    public let monitor: VideoPlayerMonitor

    public init(url: URL, control: VideoPlayerControl, monitor _monitor: VideoPlayerMonitor? = nil) {
        self.monitor = _monitor ?? VideoPlayerMonitor()
        self.control = control

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

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

        player = asset.rx.isPlayable
            .filter { $0 }
            .take(1)
            .map { _ in AVPlayer(playerItem: playerItem) }

            /// NOTE: KVO should be registerd from main-thread
            .observeOn(ConcurrentMainScheduler.instance)

            .do(onNext: { [weak monitor] player in
                guard let monitor = monitor else { return }

                player.rx.rate
                    .bind(to: monitor.rate)
                    .disposed(by: player.rx.disposeBag)

                Observable.combineLatest(playerItem.rx.status, control.setRate)
                    .filter { $0.0 == .readyToPlay }
                    .map { $1 }
                    .bind(to: player.rx.setRate)
                    .disposed(by: player.rx.disposeBag)
            })
            .asSingle()
    }
}

// MARK: VideoPlayerMonitor

/// Player Monitor
public final class VideoPlayerMonitor {

    /// NOTE: Does not `replay`.
    ///   AVPlayer.rate is also updated by the SDK.
    let rate = PublishRelay<Float>()
}

// MARK: VideoPlayerControl

/// Player Controller
public final class VideoPlayerControl {
    public let setRate: BehaviorRelay<Float>

    public init(rate: Float = 0) {
        self.setRate = BehaviorRelay<Float>(value: rate)
    }
}
