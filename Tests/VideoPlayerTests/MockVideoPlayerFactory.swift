import AVFoundation
import VideoPlayer
import RxSwift

public final class MockVideoPlayerFactory: VideoPlayerFactoryType {

    public let player: AVPlayer

    /// Grab this instance to mock player state updates.
    public let stream: VideoPlayerStream

    public init(player: AVPlayer = .init(), stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }

    public func makeVideoPlayer(_ playerItem: AVPlayerItem) -> Observable<AVPlayerWrapperType> {
        return .just(MockVideoPlayer(player: player, stream: stream))
    }
}

public final class MockVideoPlayer: AVPlayerWrapperType {

    public let player: AVPlayer
    public let stream: VideoPlayerStream

    public init(player: AVPlayer, stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }
}
