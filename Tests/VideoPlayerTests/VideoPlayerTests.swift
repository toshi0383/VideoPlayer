import AVFoundation
import RxCocoa
import RxSwift
import RxTest
import XCTest

// NOTE: `@testable` to test VideoPlayerStream.setRate and other relay and observables.
@testable import VideoPlayer

final class VideoPlayerTests: XCTestCase {

    func test_player_player() {
        let scheduler = TestScheduler(initialClock: 0)
        let dep = Dependency(scheduler: scheduler)

        scheduler.scheduleAt(300) {
            dep.isPlayable.accept(true)
            dep.playerItemStatus.accept(.readyToPlay)
        }

        let res = BehaviorRelay<AVPlayer?>(value: nil)
        _ = dep.player.player.asObservable()
            .bind(to: res)

        scheduler.advanceTo(900)
        XCTAssertEqual(res.value, dep.factory.player)
    }

    func test_control_setRate() {
        let scheduler = TestScheduler(initialClock: 0)
        let dep = Dependency(scheduler: scheduler)
        _ = dep.player.player.subscribe()
        dep.isPlayable.accept(true)

        scheduler.scheduleAt(300) {
            dep.playerRate.accept(1.0)
            dep.playerItemStatus.accept(.readyToPlay)
        }

        scheduler.scheduleAt(400) {
            dep.control.setRate.accept(1.5)
        }

        let xs = dep.stream.setRate.asObservable()

        let res = scheduler.start { xs }

        let correct = Recorded<Event<Float>>.events(
            .next(300, 1.0),
            .next(400, 1.5)
        )

        XCTAssertEqual(res.events, correct)
    }

    func test_monitor_rate() {
        let scheduler = TestScheduler(initialClock: 0)
        let dep = Dependency(scheduler: scheduler)
        _ = dep.player.player.subscribe()
        dep.isPlayable.accept(true)

        scheduler.scheduleAt(300) {
            dep.playerRate.accept(1.0)
            dep.playerItemStatus.accept(.readyToPlay)
        }

        let xs = dep.player.monitor.rate.asObservable()

        let res = scheduler.start { xs }

        let correct = Recorded<Event<Float>>.events(
            .next(300, 1.0)
        )

        XCTAssertEqual(res.events, correct)
    }
}

extension VideoPlayerTests {

    final class Dependency {
        let url = URL(string: "http://example.com/hello.m3u8")!
        let control: VideoPlayerControl
        let player: VideoPlayer
        let stream: VideoPlayerStream
        let factory: MockVideoPlayerFactory

        let isPlayable = PublishRelay<Bool>()
        let playerRate = PublishRelay<Float>()
        let isExternalPlaybackActive = PublishRelay<Bool>()
        let playerItemStatus = PublishRelay<AVPlayerItem.Status>()
        var playerDisposeBag = DisposeBag()

        init(scheduler: TestScheduler) {
            control = VideoPlayerControl()
            stream = VideoPlayerStream(isPlayable: isPlayable.asObservable(),
                                       assetDuration: .empty(),
                                       playerItemStatus: playerItemStatus.asObservable(),
                                       seekableTimeRanges: .empty(),
                                       timedMetadata: .empty(),
                                       currentTime: .empty(),
                                       periodicTime: .empty(),
                                       rate: playerRate.asObservable(),
                                       isExternalPlaybackActive: isExternalPlaybackActive.asObservable(),
                                       setPreferredPeakBitrate: { _ in },
                                       setVolume: { _ in },
                                       seekTo: { _ in .empty() },
                                       setRate: { _ in },
                                       didPlayToEndTime: .empty(),
                                       playerError: .empty(),
                                       playerDisposeBag: playerDisposeBag)

            factory = MockVideoPlayerFactory(stream: stream)
            player = VideoPlayer(asset: AVURLAsset(url: url),
                                 control: control,
                                 factory: factory,
                                 scheduler: scheduler)
        }
    }
}
