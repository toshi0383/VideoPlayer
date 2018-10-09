import AVFoundation
@testable import VideoPlayerManager // to test VideoPlayerStream
import RxCocoa
import RxSwift
import RxTest
import XCTest

final class VideoPlayerManagerTests: XCTestCase {

    func test_manager_player() {
        let scheduler = TestScheduler(initialClock: 0)
        let dep = Dependency()

        let xs = dep.manager.player.asObservable()

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
        _ = dep.manager.player.subscribe()

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
        _ = dep.manager.player.subscribe()

        scheduler.scheduleAt(300) {
            dep.playerRate.accept(1.0)
            dep.playerItemStatus.accept(.readyToPlay)
        }

        let xs = dep.manager.monitor.rate.asObservable()

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

extension VideoPlayerManagerTests {

    final class Dependency {
        let url = URL(string: "http://example.com/hello.m3u8")!
        let control: VideoPlayerControl
        let manager: VideoPlayerManager
        let stream: VideoPlayerStream
        let factory: MockVideoPlayerFactory

        let playerRate = PublishRelay<Float>()
        let playerItemStatus = PublishRelay<AVPlayerItem.Status>()

        init() {
            control = VideoPlayerControl()
            stream = VideoPlayerStream(rate: playerRate.asObservable(),
                                       playerItemStatus: playerItemStatus.asObservable())
            factory = MockVideoPlayerFactory(stream: stream)
            manager = VideoPlayerManager(url: url,
                                         control: control,
                                         factory: factory)
        }
    }
}
