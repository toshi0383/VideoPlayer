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
        let dep = Dependency()

        let xs = dep.player.player.asObservable()

        let res = scheduler.start { xs }

        let correct = Recorded<Event<AVPlayer>>.events(
            .next(200, dep.factory.player),
            .completed(200)
        )

        XCTAssertEqual(res.events, correct)
    }

    func test_control_setRate() {
        let scheduler = TestScheduler(initialClock: 0)
        let dep = Dependency()
        _ = dep.player.player.subscribe()

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
        let dep = Dependency()
        _ = dep.player.player.subscribe()

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

    static var allTests = [
        ("test_monitor_rate", test_monitor_rate),
        ("test_control_setRate", test_control_setRate),
    ]
}

extension VideoPlayerTests {

    final class Dependency {
        let url = URL(string: "http://example.com/hello.m3u8")!
        let control: VideoPlayerControl
        let player: VideoPlayer
        let stream: VideoPlayerStream
        let factory: MockVideoPlayerFactory

        let playerRate = PublishRelay<Float>()
        let isExternalPlaybackActive = PublishRelay<Bool>()
        let playerItemStatus = PublishRelay<AVPlayerItem.Status>()
        var playerDisposeBag = DisposeBag()

        init() {
            control = VideoPlayerControl()
            stream = VideoPlayerStream(isPlayable: .just(true),
                                       assetDuration: .empty(),
                                       playerItemStatus: playerItemStatus.asObservable(),
                                       seekableTimeRanges: .empty(),
                                       timedMetadata: .empty(),
                                       currentTime: .empty(),
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
            player = VideoPlayer(url: url,
                                 control: control,
                                 factory: factory)
        }
    }
}
