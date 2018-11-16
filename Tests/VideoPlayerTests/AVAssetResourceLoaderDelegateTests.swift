import RxCocoa
import RxSwift
import RxTest
import VideoPlayer
import XCTest

final class AVAssetResourceLoaderDelegateProxyTests: XCTestCase {

    private var dep: Dependency!

    override func setUp() {
        super.setUp()

        dep = Dependency()
    }

    func testDelegateProxy() {
        let asset = dep.asset
        _ = asset.resourceLoader.rx.loadingRequest
            .subscribe()
        asset.resourceLoader.rx.delegate
            .setForwardToDelegate(dep.forwardToDelegate, retainDelegate: true)

        let ex0 = expectation(description: "0")
        let ex1 = expectation(description: "1")

        _ = dep.forwardToDelegate.loadingRequestCalled
            .subscribe(onNext: {
                ex0.fulfill()
            })

        var player: AVPlayer?

        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            XCTAssertNotEqual(status.rawValue, AVKeyValueStatus.failed.rawValue)
            XCTAssertTrue(asset.isPlayable)
            ex1.fulfill()

            // Below is required to trigger loadingRequests for ex0.
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
        }

        wait(for: [ex0, ex1], timeout: 1.0)

        XCTAssertNotNil(player)
    }

}

extension AVAssetResourceLoaderDelegateProxyTests {

    private class Dependency {

        let asset: AVURLAsset

        let forwardToDelegate: MockDelegate = {
            let m = MockDelegate()
            m.shouldWait = true
            return m
        }()

        let webServer = GCDWebServer()

        let scheduler = TestScheduler(initialClock: 0)

        init() {
            webServer.addDefaultHandler(forMethod: "GET",
                                        request: GCDWebServerRequest.self,
                                        processBlock: { _ in

                                            return GCDWebServerDataResponse(text: """
                                                #EXTM3U
                                                #EXT-X-VERSION:4
                                                #EXT-X-TARGETDURATION:13
                                                #EXT-X-MEDIA-SEQUENCE:1
                                                #EXT-X-PLAYLIST-TYPE:VOD
                                                #EXT-X-DISCONTINUITY-SEQUENCE:1
                                                #EXT-X-KEY:METHOD=AES-128,URI="video-player://helloworld",IV=0xxxxxxxxxxxxxxxxxxxx
                                                #EXTINF:12.012,
                                                https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640_00001.ts
                                                #EXTINF:12.012,
                                                https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640_00002.ts
                                                #EXTINF:12.012,
                                                https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640_00003.ts
                                                #EXTINF:12.012,
                                                https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640_00004.ts
                                                #EXT-X-ENDLIST
                                                """
                                            )
            })

            webServer.start()

            let url = webServer.serverURL!.appendingPathComponent("playlist.m3u8")
            asset = AVURLAsset(url: url)
        }

        final class MockDelegate: NSObject, AVAssetResourceLoaderDelegate {
            let loadingRequestCalled = PublishRelay<Void>()
            let renewalCalled = PublishRelay<Void>()
            var shouldWait = false

            func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
                loadingRequestCalled.accept(())
                return shouldWait
            }

            func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
                renewalCalled.accept(())
                return shouldWait
            }
        }
    }
}
