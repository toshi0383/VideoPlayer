import AVFoundation
import VideoPlayer
import RxCocoa
import RxSwift

final class ViewModel {

    let playerRelay = PublishRelay<AVPlayer>()
    let rateButtonRate: Property<RateButton.Rate>

    private let _rateButtonRate = BehaviorRelay<RateButton.Rate>(value: .x1_0)

    private let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640.m3u8")!

    private var player: VideoPlayer!

    private let control = VideoPlayerControl()
    private let disposeBag = DisposeBag()

    init(requestRate: Observable<Float>,
         requestReload: Observable<Void>,
         videoPlayerFactory: VideoPlayerFactoryType = VideoPlayerFactory()) {

        rateButtonRate = Property(_rateButtonRate)

        requestRate
            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        requestReload
            .startWith(()) // NOTE: initial load
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }

                me.player = VideoPlayer(url: me.url,
                                        control: me.control,
                                        factory: videoPlayerFactory)

                me.player.objects.append(Something())

                me.player.player.asObservable()
                    .bind(to: me.playerRelay)
                    .disposed(by: me.player.playerDisposeBag)

                me.player.control.setRate
                    .map { RateButton.Rate(rawValue: $0)! }
                    .bind(to: me._rateButtonRate)
                    .disposed(by: me.player.playerDisposeBag)
            })
            .disposed(by: disposeBag)
    }
}

class Something {
    deinit {
        print("Something is deallocated")
    }
    init() {}
}
